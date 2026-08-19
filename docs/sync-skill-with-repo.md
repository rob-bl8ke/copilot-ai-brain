# Tutorial: Keeping a skill in sync with an upstream repo on a Cron schedule

This walks through the general recipe for wiring a skill to automatically stay current with
one or more upstream source repositories, on an unattended recurring schedule, with a
review gate (PR) before anything lands. It's written against **hypothetical** examples —
a `widget-core` library and a `widget-usage` skill — so you can copy the pattern for any
real skill/repo pair without needing today's specific names.

It was extracted from the concrete setup of `sync-dependent-skills` (see
[skills/sync-dependent-skills/SKILL.md](../../skills/sync-dependent-skills/SKILL.md)), which
tracks `bb-credit-domain_db-core`, `bb-credit-domain_kafka-core`, and
`bb-credit-domain_outbox-core` for four dependent skills. Read this tutorial for the *how
and why*; read that skill for a real, working example of the result.

## The problem this solves

A skill often encodes knowledge that actually lives in someone else's repo — config keys,
annotations, version numbers, setup steps. That repo keeps moving after you write the skill,
and nothing tells you when the skill has drifted out of date. The fix is a small recurring
job that:

1. Checks the upstream repo(s) for commits since the last time anyone looked.
2. If there's anything relevant, has an agent update the skill and open a PR for review.
3. Records where it left off, so next time it only looks at what's new.
4. Runs on a schedule, without you remembering to trigger it.

## Step 1 — Decide the mapping: which repo(s) feed which skill(s)

Write down, explicitly, which upstream repos a skill depends on. One skill can depend on
several repos, and one repo can feed several skills — it's a many-to-many mapping, not
1:1.

Hypothetical example:

| Dependent skill | Depends on upstream repo(s) |
|---|---|
| `skills/widget-usage/SKILL.md` | `widget-core` |
| `skills/widget-usage-e2e-tests/SKILL.md` | `widget-core` |
| `skills/widget-and-gadget-integration/SKILL.md` | `widget-core`, `gadget-core` |

This table becomes the `affects` field in the state file in Step 3 — don't hardcode it
into the skill's logic, keep it as data so it's editable without touching the runbook.

## Step 2 — Make sure you have a local, fetchable clone of each upstream repo

The sync check works by comparing git SHAs, so it needs a local clone with a working
`origin` remote for each upstream repo:

```bash
git clone https://github.com/your-org/widget-core ~/code/widget-core
git clone https://github.com/your-org/gadget-core ~/code/gadget-core
```

Record each repo's current HEAD SHA on the branch you'll track (almost always `main`,
unless the project publishes packages from a `develop`/release branch before merging —
check with `git ls-remote --heads origin` rather than assuming the branch exists):

```bash
git -C ~/code/widget-core rev-parse HEAD
git -C ~/code/gadget-core rev-parse HEAD
```

These become the **baseline SHAs** you seed the snapshot with in Step 3 — you're telling
the system "everything up to here is already accounted for; only show me what comes
after."

## Step 3 — Create the sync skill and its state file

Create a new skill directory, e.g. `skills/sync-widget-skills/`, with two files:

**`skills/sync-widget-skills/SKILL.md`** — the runbook. Frontmatter is just `name`,
`description`, and an `argument-hint` for a manual-override flag:

```markdown
---
name: sync-widget-skills
description: "Checks widget-core and gadget-core for upstream commits since the last
  recorded sync, and updates the dependent skills when something relevant changed. Runs
  on a scheduled task, or on demand."
argument-hint: "[force] - pass 'force' to bypass the time gate and run the real check now"
---

# Sync Widget Skills

## Fixed scope (do not exceed)
- Read-only on the exact local_clone paths listed in state/sync-state.json — never clone
  a new repo, never touch an unlisted path.
- Writes limited to the skill directories named in the mapping table.
- Every write goes through a branch + PR. Never commit or push to main directly, never
  merge, never force-push, never delete a branch it didn't create.

## Procedure
1. Read state/sync-state.json.
2. Gate check: unless invoked with `force`, skip if less than N days since
   last_full_check_at.
3. For each repo entry: fetch, compare latest SHA to last_synced_sha.
4. For repos with new commits: review the log/diff for consumer-relevant changes
   (version bumps, config changes, deprecations) — ignore internal/test-only churn.
5. For each affected skill: edit only if genuinely impacted.
6. Update state: advance last_synced_sha/last_synced_at per repo, and last_full_check_at,
   regardless of outcome.
7. Branch, commit, push, open a PR describing the SHA ranges and what changed (or that
   nothing did). Never merge it yourself.
```

**`skills/sync-widget-skills/state/sync-state.json`** — the config *and* the snapshot in
one file, seeded with today's baseline SHAs:

```json
{
  "last_full_check_at": "2026-08-19T16:54:49Z",
  "repos": {
    "widget-core": {
      "url": "https://github.com/your-org/widget-core",
      "local_clone": "~/code/widget-core",
      "branch": "main",
      "last_synced_sha": "<HEAD SHA from step 2>",
      "last_synced_at": "2026-08-19T16:54:49Z",
      "affects": [
        "skills/widget-usage/SKILL.md",
        "skills/widget-usage-e2e-tests/SKILL.md",
        "skills/widget-and-gadget-integration/SKILL.md"
      ]
    },
    "gadget-core": {
      "url": "https://github.com/your-org/gadget-core",
      "local_clone": "~/code/gadget-core",
      "branch": "main",
      "last_synced_sha": "<HEAD SHA from step 2>",
      "last_synced_at": "2026-08-19T16:54:49Z",
      "affects": [
        "skills/widget-and-gadget-integration/SKILL.md"
      ]
    }
  }
}
```

Why one file for both config and state: it's user-editable (add/remove a repo, change
`affects`, repoint `local_clone`) *and* it's what the agent updates after every run — no
separate manifest to go stale, and no need to touch the skill's own logic to reconfigure
what it tracks.

Why a **time gate** instead of a plain weekly cron: see Step 5 — the schedule that
actually triggers this skill runs more often than you want the real check to happen, and
the gate is what turns "daily trigger" into "weekly behavior" without depending on the
cron firing at one precise, fragile moment.

## Step 4 — Lock down the blast radius before letting it run unattended

Because the point is to run this with **no manual approval per run**, the scope has to be
capped structurally, not by hoping the agent behaves:

- **Repo allowlist**: only the exact `local_clone` paths in the state file — no arbitrary
  `git clone`, no reading anything else on disk.
- **Write allowlist**: only the skill directories named in the mapping table.
- **PR-only, never merge**: every write — even a pure timestamp bump in the state file —
  goes through `git checkout -b sync/...` → commit → push → `gh pr create`. Never a direct
  commit to `main`, never `gh pr merge`, never `--force`, never `git reset --hard`, never
  deleting a branch it didn't create.

Then add narrowly-scoped permission entries to `.claude/settings.local.json` so those
specific commands are pre-approved and nothing broader is:

```json
{
  "permissions": {
    "allow": [
      "Bash(git -C ~/code/widget-core fetch origin main)",
      "Bash(git -C ~/code/widget-core rev-parse origin/main)",
      "Bash(git -C ~/code/widget-core log --oneline *)",
      "Bash(git -C ~/code/widget-core diff --stat *)",
      "Bash(git -C ~/code/gadget-core fetch origin main)",
      "Bash(git -C ~/code/gadget-core rev-parse origin/main)",
      "Bash(git -C ~/code/gadget-core log --oneline *)",
      "Bash(git -C ~/code/gadget-core diff --stat *)",
      "Bash(git checkout -b sync/*)",
      "Bash(git push origin sync/*)",
      "Bash(gh pr create *)",
      "Edit(skills/widget-usage/**)",
      "Edit(skills/widget-usage-e2e-tests/**)",
      "Edit(skills/widget-and-gadget-integration/**)",
      "Edit(skills/sync-widget-skills/**)",
      "Write(skills/sync-widget-skills/**)"
    ]
  }
}
```

This file is normally gitignored (it's local, machine-specific permission config) — check
with `git check-ignore -v .claude/settings.local.json` before assuming it needs to be
committed.

The allowlist *is* the security boundary here — not the wording of the skill's prompt.
If the skill's logic ever tries something outside this list, it should hit a permission
wall rather than silently succeeding.

## Step 5 — Configure the Cron schedule (via the scheduled-tasks MCP)

This is the actual "hook it up to Cron" step. It's done through the **`scheduled-tasks`
MCP server** (tool names like `mcp__scheduled-tasks__create_scheduled_task`), which you can
also drive via the `/schedule` skill/command.

Create the task:

- `taskId`: a short kebab-case id, e.g. `sync-widget-skills`.
- `cronExpression`: a **daily** cron string, e.g. `"35 11 * * *"` (11:35am local) — not a
  literal weekly one. This is the important trick: schedule it to fire *more often* than
  you actually want it to act, and let the skill's own time-gate (Step 3) decide whether a
  given firing is a real check or a silent no-op. A once-a-week cron is fragile — if the
  machine is off/asleep at that exact moment, you silently lose a whole week. A daily
  fire-and-gate catches up the next day the app happens to be open instead.
- `notifyOnCompletion: false` — so the many no-op days don't spam a notification; the only
  visible signal on a real sync is the PR itself.
- `prompt`: a fully self-contained instruction (the task has no memory of this
  conversation), e.g.:

  > Working directory: `~/code/my-skills`. Run the `sync-widget-skills` skill exactly as
  > documented in `skills/sync-widget-skills/SKILL.md`: check the gate, and if due, fetch
  > `widget-core`/`gadget-core`, diff against the last recorded SHA, update only genuinely
  > impacted skills, advance the state file, and open a PR (never push or merge to `main`
  > directly). If anything can't be done safely, stop and explain why in a PR/commit note
  > rather than working around it.

Example tool call shape:

```json
{
  "tool": "mcp__scheduled-tasks__create_scheduled_task",
  "taskId": "sync-widget-skills",
  "description": "Daily-triggered, weekly-gated check of widget-core/gadget-core for upstream changes",
  "cronExpression": "35 11 * * *",
  "notifyOnCompletion": false,
  "prompt": "<the self-contained prompt above>"
}
```

## Step 6 — Understand how this actually runs (no OS cron, no hidden daemon)

This is the part that's easy to assume-wrong, so it's worth being precise about, based on
directly checking a running system:

- `crontab -l` and `launchctl list` show **nothing** for the scheduled task. It is not a
  real OS-level cron job or launchd agent.
- The schedule is held and evaluated entirely by the **Claude Desktop app's own running
  process** (visible in `ps aux` as `/Applications/Claude.app/.../MacOS/Claude`, running
  continuously). When a scheduled time arrives, that resident app process spawns a `claude`
  CLI child process to actually execute the task's prompt.
- Practical consequence: **the schedule only fires while Claude Desktop is running.** If
  you fully quit the app (not just close a window), or the machine sleeps/is off, nothing
  fires at that moment. The tool's own documentation confirms the fallback: "if the app is
  closed when a task is due, it runs on next launch" — i.e. it catches up, it doesn't
  silently vanish, but it's not a guaranteed-at-the-exact-minute system the way a real
  crontab entry would be.
- This is exactly why Step 5 uses a **daily** cron plus a **skill-level time gate** rather
  than a literal weekly cron: the gate absorbs the unreliability of "was the app open at
  that exact moment," turning it into "was the app open at least once during the window."
- If you need a guarantee independent of the desktop app being open at all, that requires
  a real OS-level `launchd`/`cron` job invoking the `claude` CLI headlessly — outside what
  the scheduled-tasks MCP tool provides on its own.

## Step 7 — How to inspect, run manually, pause, or remove it later

- **List all scheduled tasks**: `mcp__scheduled-tasks__list_scheduled_tasks` — shows each
  task's cron expression, enabled state, `nextRunAt`/`lastRunAt`, and the on-disk `path` to
  its prompt (stored as `{taskId}/SKILL.md` under `~/.claude/scheduled-tasks/` — outside
  any git repo).
- **Read the exact prompt** that will fire: `Read` the `path` from the listing above.
- **Run it manually right now**, bypassing the cron entirely: invoke the *skill itself*
  (not the scheduled task) directly — e.g. `/sync-widget-skills force` — since the
  scheduled task is only ever a caller of that skill, never the only entry point. Use
  `force` to skip the time gate when you don't want to wait out the window.
- **Pause without deleting**: `mcp__scheduled-tasks__update_scheduled_task` with
  `enabled: false` (and `true` to resume).
- **Delete**: `mcp__scheduled-tasks__delete_scheduled_task` — leaves the prompt file on
  disk for reference even after the task stops running.

## Quick checklist for doing this again with a new skill/repo pair

1. Write down the repo → skill mapping.
2. Confirm each upstream repo has a local, fetchable clone and note its baseline SHA
   (check the actual branch name via `git ls-remote --heads origin` — don't assume
   `main`/`develop`).
3. Create the sync skill + seed its `state/sync-state.json` with the mapping and baseline
   SHAs, including a `last_full_check_at` gate timestamp.
4. Add narrowly-scoped entries to `.claude/settings.local.json` covering exactly the
   fetch/diff/branch/push/PR commands and the affected skill directories — nothing
   broader.
5. Create a **daily** scheduled task via the `scheduled-tasks` MCP whose prompt tells it to
   run the skill; let the skill's own gate decide whether a given day is a real check.
6. Remember the schedule only fires while the desktop app is running — that's *why* the
   gate exists, not a gap to fix.
7. Test with `force` before waiting for the real schedule to prove the gate/fetch/PR path
   works end-to-end.
