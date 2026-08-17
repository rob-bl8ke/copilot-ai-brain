# Output Structure

Use this structure for generated language standards skills unless the language strongly suggests a different split.

## Folder Shape

```text
<language>-standards/
├── SKILL.md
└── references/
    ├── language-and-design.md
    ├── types-and-data.md
    ├── errors-and-resources.md
    ├── concurrency.md
    ├── io-and-platform.md
    ├── code-quality.md
    ├── legacy-and-anti-patterns.md
    └── agent-behaviour.md
```

When the target is version-specific, include the version in the skill name if it materially changes guidance, such as `java-21-standards`.

## `SKILL.md` Shape

Keep `SKILL.md` compact. It should include:

- Frontmatter with `name` and a concrete trigger-heavy `description`.
- Target environment.
- Operating rules.
- Classification meanings.
- Always-loaded baseline standards.
- Non-standards.
- Section guide linking to references.
- Workflow.

The `SKILL.md` contains decision policy. References contain detailed knowledge.

## Target Environment

State the baseline explicitly:

```text
Target: <Language> <version>
Runtime: <runtime/platform version>
Standard library: <baseline>
Preview features: excluded unless explicitly requested
Frameworks: excluded; use framework skills as overlays
```

## Operating Policy Example

```text
Apply these operating principles:
- prefer idiomatic modern <language>
- preserve repository conventions
- make the smallest coherent change
- prefer immutable state where practical
- avoid unnecessary abstractions
- use stable <language/version> features
- do not introduce preview features unless requested
- use modern standard-library APIs
- preserve contracts and behavior
- follow referenced standards when the task touches those areas
```

## Non-Standards

Every generated skill should explicitly document areas where it refuses to impose a universal opinion.

Common examples:

- Formatter choice.
- Indentation width.
- Exact line length.
- Arbitrary method-length limits.
- Arbitrary class-length limits.
- Project architecture.
- Build system.
- Framework choice.
- Testing framework.
- Persistence framework.
- Deployment model.

This prevents the language skill from becoming overly dogmatic and preserves room for repository-specific conventions.

## Reference File Shape

Use concise, searchable reference files. A good reference file usually contains:

```text
# <Topic>

Use when <specific trigger>.

MUST:
- ...

SHOULD:
- ...

CONSIDER:
- ...

AVOID:
- ...

NEVER:
- ...

Agent guardrails:
- ...
```

Omit empty classifications rather than filling space.
