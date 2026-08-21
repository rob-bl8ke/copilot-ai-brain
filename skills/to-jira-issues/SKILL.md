---
name: to-jira-issues
description: Create or evolve a single, well-structured Jira issue (business content above technical task content) directly via the Atlassian/Jira MCP connector, from a phase/task reference, a free-text requirement, a broader feature that needs breaking into vertical-slice tickets, or an existing live Jira issue. Use when the user wants a Jira issue written up or created, a requirement turned into a ticket, a phase/spec broken into tickets, or an existing Jira issue updated because requirements changed. The Jira issue itself is the source of truth — no local file is generated.
argument-hint: A phase/task reference (3.3, Phase 3, 3.1-3.4), a free-text requirement, a broader feature description to break into tickets, or a Jira issue key/URL.
---

## Default instructions (always apply)

- Produce **one Jira issue per item**: a single combined issue body that reads business context first, then implementation detail, so the whole ticket can be created in one shot instead of being scattered across separate documents. See [references/templates.md](references/templates.md) for the exact structure.
- The Jira issue is the source of truth — do not write a local `.md` file mirroring it. Draft the body in the conversation for the user to review before it's created or updated.
- A diagram, when warranted, is embedded directly in the issue body's Task Details (see references/templates.md) rather than kept as a separate file, since there's no local artifact for it to live alongside.
- Size single tickets to roughly 2-3 days for an average developer (about 5 hours/day) as a rule of thumb — in breakdown mode this is superseded by the tracer-bullet sizing rule in Stage 4 below.
- For verification steps, use `mvn` (not `./mvnw`).
- Output markdown only, no implementation code.
- Do not invent architecture, dependencies, deliverables, acceptance criteria, or diagrams that aren't supported by the resolved source material.
- **Jira write guardrail:** you may *read* any Jira issue/comment freely via the Atlassian MCP connector, and *edit* an existing issue when the user is explicitly evolving it (with confirmation — see Stage 6). You must **never create a new Jira issue** unless the user explicitly asks you to create one.
- **Always report the issue number/key back to the requestor immediately after creating a new Jira issue** — this is the one piece of information the user needs to find their ticket, and it must never be left implicit in a longer message. Include the issue key and, if available, a direct URL.
- **Jira issue type:** default to **Story**. Only use a different type (e.g. Bug, Spike) when the requester specifically asks for that type — never infer Bug/Spike/Task from the content alone.
- **Jira acceptance criteria field:** the acceptance criteria must exist in **both** places — the `#### Acceptance Criteria` section of the issue description (for readability) **and** the dedicated Jira `acceptance criteria` field (so it's tracked as structured data), never just one. Each AC item must be formatted as a checkbox (action item) in both places — use `- [ ] {criterion}` in markdown, or the equivalent checkbox/action-item type in the Jira field, so the same list appears as real Jira checkboxes in the dedicated field.
- **No separate task-spec comment:** the task detail already lives in the issue body itself (below the business content, in the same ticket), so don't post a duplicate task write-up as a comment.
- **Never close or modify a parent issue.** When breaking a phase/spec down into child issues, or evolving a child issue, leave whatever parent/epic it belongs to untouched — only the issue actually being created or edited changes.

---

## Stage 1 — Resolve the source

Work from whatever is already in the conversation context first — don't ask the user to re-supply a spec/plan already read this session, a requirement already discussed, or an issue already shown earlier in the conversation.

If the args (or the user's message) contain a reference, fetch and read it **in full** before doing anything else:

| Reference looks like | Action |
|---|---|
| A local file path (spec/plan doc) | `Read` it in full |
| A Jira issue key (e.g. `BBCDA-1234`) or a Jira issue URL | Use the Atlassian MCP connector — `getJiraIssue`, then fetch its comments — and read the full issue body and every comment, not a summary |
| Any other URL (Confluence page, doc link, etc.) | Fetch it and read the full body |

Fetched content becomes input to whichever stage runs next — single-item generation, breakdown drafting, or evolve mode's "new information."

If no spec plan document is available and one is needed to resolve a phase/task reference, ask the user to supply it before drafting anything.

## Stage 2 — Explore the codebase (when the work touches code)

Skip this stage only for a pure requirement clarification with no code impact. Otherwise, before drafting any title, story, or task detail:

1. Explore the relevant area of the codebase if it hasn't already been explored this session (use the Explore agent for anything broader than a couple of targeted lookups).
2. Extract the domain glossary vocabulary already in use — entity names, status enum values, event names, field names (e.g. `RequestStatus`, `DispatchStatus`, `CommunicationSent`/`CommunicationFailed`, `template_identifier`). Use these exact terms in the issue title and body instead of paraphrasing them. The title must be concise and use this vocabulary rather than generic phrasing.
3. Check for and respect any ADRs relevant to the area being touched.
4. Look for prefactoring opportunities: "make the change easy, then make the easy change." Anything found becomes its own ticket, sequenced first, blocking whatever it unblocks.

## Stage 3 — Classify the request

Decide which mode applies before drafting output:

1. **Evolve mode** — the reference resolved in Stage 1 is a live Jira issue, and the user is supplying new information (changed requirements) to fold into it. → Stage 6.
2. **Breakdown mode** — the request describes a broader feature or spec area that isn't already a single scoped item (e.g. a whole phase that itself isn't one task, or a wide free-text feature ask). → Stage 4, then Stage 5 after approval.
3. **Single-item mode** — the request already resolves to one scoped item:
   - A phase/task reference, range, or list (`3.3`, `Phase 3`, `3.1-3.4`, `3.1, 3.3, 4.2`) — expand a phase-with-tasks into one generated item per task; a phase without tasks is itself the item. If any part is ambiguous or unresolvable against the active plan, ask a short clarifying question instead of guessing.
   - A free-text requirement — if it was explicitly provided, use it directly. If it had to be inferred from chat context, state the inferred requirement as one clearly labelled sentence and get user confirmation before drafting.
   → Stage 5 directly.

Never merge multiple adjacent tasks/items into one generated item, and never expand scope beyond what the resolved source actually supports.

## Stage 4 — Breakdown drafting (breakdown mode only)

Full methodology: [references/slicing.md](references/slicing.md). Summary:

- Draft **tracer-bullet tickets**: each is a vertical slice cutting a narrow but *complete* path through every layer it touches (schema, API, service, tests, UI where relevant) — never a horizontal single-layer slice.
- Each slice must be demoable or verifiable on its own, and sized to fit a single fresh context window.
- **Exception — wide mechanical refactors** (one change whose blast radius fans across the whole codebase): sequence as expand → migrate batches → contract instead of forcing a tracer bullet. See the reference doc for the full rule, including the integration-branch fallback when batches can't stay green alone.
- Prefactoring tickets from Stage 2 come first, blocking the slices/batches they unblock.
- Give every ticket explicit **blocking edges** — which other tickets must complete before it can start; a ticket with no blockers can start immediately.
- Present the breakdown as a numbered list. For each ticket show: **Title**, **Blocked by**, **What it delivers**.
- Ask the user: does the granularity feel right (too coarse/fine)? Are the blocking edges correct? Should anything merge or split? Iterate until the user approves.
- **Do not draft a full issue body, and do not create any Jira issue, until the breakdown is approved.**

Once approved, treat each approved ticket as a single-item generation pass through Stage 5, carrying its blocking edges into that ticket's `Dependencies/Blockers` field.

## Stage 5 — Generate and create the issue

Full template: [references/templates.md](references/templates.md). In short, for each item (from single-item mode, or an approved breakdown ticket):

1. Draft the combined issue body — business content (title, user story, short description, estimation factors, blocker note), kept high-level enough that the team can gauge impact and scope for estimation without reading code, then a horizontal rule, then `## Task Details` (goal, spec foundation, inputs, scope, deliverables, acceptance criteria, dependencies/blockers, verification, notes/risks, and an embedded diagram if one is warranted).
2. Show the drafted body to the user in the conversation for review — this is the only draft artifact; nothing is written to disk.
3. Per the Jira write guardrail, do **not** call `createJiraIssue` unless the user explicitly asks you to create the Jira issue — ask "Want me to create this as a Jira issue?" if they haven't already said so in this request. Once confirmed and the Atlassian MCP connector is available:
   - Create the issue as type **Story** by default — only use a different type if the requester specifically asked for one (e.g. Bug, Spike) — with title = the concise domain-vocabulary title, description = the full combined body.
   - Write the Acceptance Criteria bullets into the dedicated Jira Acceptance Criteria field as checkboxes, per the guardrail above, so they exist both in the description and in that field.
   - If this issue was carried over from an approved breakdown (Stage 4) with a parent/epic, link it to that parent as normal — but never modify or close the parent issue itself.
   - **Immediately report the created issue's key and URL back to the user** — every first-time creation must end with this, not just a general "done."
   - If the connector isn't available, tell the user and offer the drafted body as plain text for them to paste in manually.

## Stage 6 — Evolve mode

- The target is always a live Jira issue (there is no local file to target, since the issue is the source of truth) — use the body/comments already fetched in Stage 1 as the "existing artifact" being evolved.
- Merge the new information into the existing structure: update only the sections it actually affects, leave everything else untouched. This is an edit, not a regeneration — never rewrite the issue from scratch when evolving it.
- **Before writing an update back to the live Jira issue**, draft the change and show it to the user, then get explicit confirmation before calling the Jira edit tool — this is a side-effectful action on a shared system.
- If the change affects the Acceptance Criteria section, update the dedicated Jira AC field to match, not just the description body.
- Never create a new Jira issue while evolving (or in any other mode) unless the user explicitly asks for that.
