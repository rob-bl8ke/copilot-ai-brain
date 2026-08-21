---
name: java-code-review
description: "Review the changes since a fixed point (commit, branch, tag, or merge-base) along two axes: Standards (does the code follow this skills base's *-standards skills, e.g. java-21-standards, plus any repo-local CODING_STANDARDS.md) and Spec (does the code match what the originating Jira issue, e.g. BBCDA-2417, asked for?). Runs both reviews in parallel sub-agents and reports them side by side. Use when the user wants to review a branch, work-in-progress changes, or asks to \"review since X\"."
---

Two-axis review of the diff between `HEAD` and a fixed point the user supplies:

- **Standards**: does the code conform to this repo's documented coding standards (this skills base's `java-21-standards` / `java-21-springboot-standards` skills, plus any repo-local `CODING_STANDARDS.md`/`CONTRIBUTING.md`)?
- **Spec**: does the code faithfully implement the originating Jira issue (e.g. `BBCDA-2417`)?

Both axes run as **parallel sub-agents** so they don't pollute each other's context, then this skill aggregates their findings.

## Process

### 1. Pin the fixed point

Whatever the user said is the fixed point (a commit SHA, branch name, tag, `main`, `HEAD~5`, etc.). If they didn't specify one, ask for it.

Capture the diff command once: `git diff <fixed-point>...HEAD` (three-dot, so the comparison is against the merge-base). Also note the list of commits via `git log <fixed-point>..HEAD --oneline`.

Before going further, confirm the fixed point resolves (`git rev-parse <fixed-point>`) and the diff is non-empty. A bad ref or empty diff should fail here, not inside two parallel sub-agents.

### 2. Identify the spec source (Jira)

Look for the originating Jira issue, in this order:

1. **Branch name** — extract a key matching `[A-Z][A-Z0-9]+-\d+` (e.g. `BBCDA-2417`) from the current branch name (`git branch --show-current`), typically a prefix like `BBCDA-2417-add-thing`.
2. **Commit messages** — if the branch name doesn't yield a key, scan the commit messages in the log range (from step 1) for the same pattern.
3. If a key is found, fetch the full issue via the Atlassian MCP connector directly — `getJiraIssue` for the description/fields, plus its comments — and read it in full, not a summary. No intermediate tracker-doc file is needed; this repo already wires up the Atlassian MCP connector (see the `to-jira-issues` skill for the same pattern).
4. If no key is found:
   - A path or Jira key the user passed as an argument.
   - A spec file under `docs/temp/issues/` matching the branch name or feature.
   - If nothing is found, ask the user where the spec is (a Jira key, a URL, or a file path). If they say there isn't one, the **Spec** sub-agent will skip and report "no spec available".

### 3. Identify the standards sources

Don't hardcode a skill name — the language/version in play changes over time (e.g. `java-21-standards` today, `java-25-standards` tomorrow). Discover what's actually present instead, by matching the `*-standards` naming convention this skills base uses (e.g. `java-21-standards`, `java-21-springboot-standards`).

**Search every root, not just the working directory.** This skill normally runs with the CWD set to the *service repo under review*, not to the skills base — so a bare `skills/*/SKILL.md` glob finds nothing. Resolve the skills base from the absolute path of **this file**: this `SKILL.md` sits at `<skills-base>/skills/code-review/SKILL.md`, so its sibling skills are `<skills-base>/skills/*/SKILL.md`. Substitute that real path below.

```
grep -l '^name:.*-standards$' \
  <skills-base>/skills/*/SKILL.md \
  ./.claude/skills/*/SKILL.md \
  "$HOME"/.claude/skills/*/SKILL.md 2>/dev/null
```

Deduplicate the results by each skill's `name:` value. If the same skill name appears in more than one root, the copy inside the repo under review wins — same precedence as `CODING_STANDARDS.md` below.

**If this yields zero matches, stop and say so.** Report which roots were searched and ask the user for the path to the skills base. Do not continue into the sub-agents on the smell baseline alone while presenting the result as a Standards review — a Standards axis that silently found no standards is the failure this step exists to catch.

Read every match's `SKILL.md`, and pull in its `references/` docs too when the diff touches an area detailed enough to need them. If a match's classification scheme differs from MUST/SHOULD/CONSIDER/AVOID/NEVER, use whatever scheme that skill actually documents — don't assume Java's.

On top of those, also pick up anything the target repo itself documents, such as `CODING_STANDARDS.md` or `CONTRIBUTING.md` — a **repo-local standard always overrides** the skills-base standards where the two disagree.

Beyond both of those, the Standards axis always carries the **smell baseline** below: a fixed set of Fowler code smells (_Refactoring_, ch.3) that applies even when nothing else is documented. Two rules bind it:

- **Documented standards override.** A documented standard (repo-local or from the standards skills) always wins; where it endorses something the baseline would flag, suppress the smell.
- **Always a judgement call.** Each smell is a labelled heuristic ("possible Feature Envy"), never a hard violation. Like any standard here, skip anything tooling already enforces.

Each smell reads *what it is* → *how to fix*; match it against the diff:

- **Mysterious Name**: a function, variable, or type whose name doesn't reveal what it does or holds. → rename it; if no honest name comes, the design's murky.
- **Duplicated Code**: the same logic shape appears in more than one hunk or file in the change. → extract the shared shape, call it from both.
- **Feature Envy**: a method that reaches into another object's data more than its own. → move the method onto the data it envies.
- **Data Clumps**: the same few fields or params keep travelling together (a type wanting to be born). → bundle them into one type, pass that.
- **Primitive Obsession**: a primitive or string standing in for a domain concept that deserves its own type. → give the concept its own small type.
- **Repeated Switches**: the same `switch`/`if`-cascade on the same type recurs across the change. → replace with polymorphism, or one map both sites share.
- **Shotgun Surgery**: one logical change forces scattered edits across many files in the diff. → gather what changes together into one module.
- **Divergent Change**: one file or module is edited for several unrelated reasons. → split so each module changes for one reason.
- **Speculative Generality**: abstraction, parameters, or hooks added for needs the spec doesn't have. → delete it; inline back until a real need shows.
- **Message Chains**: long `a.b().c().d()` navigation the caller shouldn't depend on. → hide the walk behind one method on the first object.
- **Middle Man**: a class or function that mostly just delegates onward. → cut it, call the real target direct.
- **Refused Bequest**: a subclass or implementer that ignores or overrides most of what it inherits. → drop the inheritance, use composition.

### 4. Spawn both sub-agents in parallel

**Standards sub-agent prompt** should include:

- The full diff command and commit list.
- The full content of every standards skill discovered in step 3 (and any `references/` docs pulled in), plus any repo-local `CODING_STANDARDS.md`/`CONTRIBUTING.md`, **plus the smell baseline from step 3 pasted in full** (the sub-agent has no other access to any of this).
- The brief: "Report, per file/hunk where relevant, (a) every place the diff violates a documented standard: cite the standard, its source skill/file, and its classification if the source defines one (e.g. MUST/SHOULD/CONSIDER/AVOID/NEVER); and (b) any baseline smell you spot: name it and quote the hunk. Distinguish hard violations from judgement calls: documented-standard breaches can be hard (especially at the strictest classification level, e.g. MUST/NEVER), but baseline smells are always judgement calls, and a documented standard overrides the baseline. Skip anything tooling enforces. Under 400 words."

**Spec sub-agent prompt** should include:

- The diff command and commit list.
- The fetched Jira issue key, description, and comments (or the path/contents of whatever spec source was resolved in step 2).
- The brief: "Report: (a) requirements the spec asked for that are missing or partial; (b) behaviour in the diff that wasn't asked for (scope creep); (c) requirements that look implemented but where the implementation looks wrong. Quote the Jira issue text for each finding, and reference the issue key (e.g. `BBCDA-2417`). Under 400 words."

If the spec is missing, skip the Spec sub-agent and note this in the final report.

### 5. Aggregate

Present the two reports under `## Standards` and `## Spec` headings, verbatim or lightly cleaned. Do **not** merge or rerank findings, because the two axes are deliberately separate (see _Why two axes_).

End with a one-line summary: total findings per axis, and the worst issue _within each axis_ (if any). Don't pick a single winner across axes: that's the reranking the separation exists to prevent.

This is a read-only review: findings are reported in chat only. Do not write a comment back to the Jira issue, consistent with the write guardrail used by `to-jira-issues` — creating or editing Jira content requires the user to explicitly ask for it separately.

## Why two axes

A change can pass one axis and fail the other:

- Code that follows every standard but implements the wrong thing → **Standards pass, Spec fail.**
- Code that does exactly what the issue asked but breaks the project's conventions → **Spec pass, Standards fail.**

Reporting them separately stops one axis from masking the other.
