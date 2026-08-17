# Agent Behaviour

Use when deciding how an AI coding agent should apply Python 3.11 standards without overreaching.

## MUST

- Determine whether the change is language-level Python or belongs to a child framework, testing, packaging, data, or infrastructure skill.
- Preserve repository conventions over generic guidance when they conflict.
- Make the smallest coherent change that solves the task.
- Preserve public behavior, public names, data formats, and exception contracts unless explicitly changing them.
- Keep generated code compatible with Python 3.11.x.
- Load only reference files relevant to the code being changed.

## SHOULD

- Prefer standard-library solutions before adding dependencies.
- Match surrounding style in touched code, even when it differs from generic PEP 8 preferences.
- Improve nearby clarity when it directly supports the requested change.
- Add focused tests or use existing verification commands when the repository already has them and the task warrants it.
- Explain deviations from this skill when correctness, compatibility, or local convention requires them.

## CONSIDER

- Suggest a child skill when the work clearly depends on Django, FastAPI, Flask, SQLAlchemy, pytest, packaging, data science, cloud, or deployment conventions.
- Propose broader modernization separately when discovered issues are real but out of scope.

## AVOID

- Repository-wide formatting, import sorting, type annotation, async conversion, or pathlib conversion unless requested.
- Adding validation frameworks, dependency injection containers, base classes, factories, or configuration systems for simple code.
- Treating PEP 8 style preferences as API-breaking mandates.
- Replacing established local idioms without a concrete maintainability or correctness reason.

## NEVER

- Modify unrelated files to satisfy this skill.
- Add a package manager, linter, formatter, type checker, test framework, web framework, ORM, or deployment tool from this skill alone.
- Break compatibility only to make code look more modern.
- Suppress errors silently to make generated code pass a narrow scenario.

## Composability Checks

- A Django, FastAPI, Flask, SQLAlchemy, pytest, or packaging skill can add ecosystem rules without contradicting this base skill.
- A formatter or linter skill can define exact line length, quote style, and rule selection without changing this skill's language-level guidance.
- A deployment or infrastructure skill can define runtime, environment, logging, secrets, and process rules without this skill taking ownership of those concerns.
- If an overlay needs to contradict a MUST or NEVER here, re-check whether the base rule is too broad or the overlay is relying on unsafe behavior.
