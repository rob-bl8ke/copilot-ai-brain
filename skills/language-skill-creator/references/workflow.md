# Workflow

Use this process to create a language standards skill from a language, runtime, existing standards catalogue, or prior language-specific conversation.

## 1. Establish Scope

Capture the target before writing rules:

- Language name.
- Language version.
- Runtime or platform version.
- Standard-library baseline.
- Stable language features.
- Preview or experimental features.
- Explicitly excluded frameworks and tools.
- Repository conventions that override generic guidance.

If the target version is unknown, ask one short clarifying question. Do not generate a versionless language standards skill unless the user explicitly asks for one.

## 2. Build Standards Catalogue

Catalogue candidate standards before drafting the final skill. Cover language idioms, type system, state, errors, collections, concurrency, I/O, API design, testing/testability, performance, security, legacy practices, and agent behavior.

Do not decide section boundaries too early. Start broad, then merge or split based on how much real guidance exists for the language.

## 3. Classify Rules

Assign every candidate rule one of these strengths:

- MUST
- SHOULD
- CONSIDER
- AVOID
- NEVER

Prefer lower strength when a rule is mainly contextual. Reserve MUST and NEVER for correctness, safety, contracts, language semantics, or broadly harmful patterns.

## 4. Remove False Standards

Challenge each rule that sounds universal but may be a local preference. If a rule cannot be justified by correctness, safety, maintainability, common language idiom, or strong ecosystem convention, move it to `Non-Standards` or omit it.

## 5. Identify Boundaries

Separate base language concerns from likely child skills:

- Frameworks.
- Build tools.
- Testing frameworks.
- Persistence libraries.
- Serialization libraries.
- Web frameworks.
- Infrastructure and deployment.
- Architectural style.

The base language skill may mention boundary principles, but should not encode detailed framework behavior.

## 6. Extract Operating Policy

Keep `SKILL.md` short. It should hold the always-active decision policy, classification definitions, section guide, non-standards summary, and workflow.

Move detailed knowledge into references so the agent loads only the sections relevant to the task.

## 7. Write References

Create reference files for detailed standards. Each reference should be focused enough that it can be loaded independently during coding or review.

Use consistent headings where useful:

- When to use this reference.
- MUST.
- SHOULD.
- CONSIDER.
- AVOID.
- NEVER.
- Agent guardrails.

## 8. Validate

Test the skill against at least one realistic composition, such as:

- `<language>-standards` plus `<language>-<framework>-standards`.
- `<language>-standards` plus a build-tool skill.
- `<language>-standards` plus a testing skill.

If the overlay would need to contradict the base skill, revise the boundary or weaken an overbroad rule.
