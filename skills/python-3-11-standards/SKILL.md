---
name: python-3-11-standards
description: Use when writing, reviewing, or refactoring Python 3.11.x code. Applies language-level Python standards, PEP 8 style guidance, PEP 20 design principles, Python 3.11 standard-library practices, typing guidance, error/resource handling, concurrency guardrails, and AI-agent anti-overengineering rules. Do not use as a substitute for Django, FastAPI, Flask, pytest, packaging, ORM, data-science, infrastructure, or deployment standards.
---

# Python 3.11 Standards

Write idiomatic, maintainable Python 3.11 code using stable language features and the Python 3.11 standard library. This skill is policy-oriented; load the referenced files only when the task touches that area.

## Target Environment

Target: Python 3.11.x.
Runtime: CPython 3.11.x by default; avoid relying on CPython-only behavior unless the repository explicitly targets CPython internals.
Standard library: Python 3.11 standard library.
Stable features: structural pattern matching, `dataclasses`, built-in generic aliases, `|` unions, `typing.Self`, `Required`, `NotRequired`, `LiteralString`, `ExceptionGroup`, `except*`, `BaseException.add_note`, `asyncio.TaskGroup`, `asyncio.timeout`, `tomllib`, `datetime.UTC`, `enum.StrEnum`.
Preview or experimental features: excluded unless explicitly requested.
Frameworks and tools: excluded; child skills handle frameworks, package managers, formatters, linters, test runners, ORMs, web servers, cloud, CI/CD, and deployment.

## Operating Rules

- MUST preserve runtime behavior, public contracts, and repository conventions unless the task explicitly changes them.
- MUST treat PEP 8 as the default style baseline while honoring its rule that project-local consistency takes precedence.
- MUST prefer explicit, readable code over clever, magical, or overly generic code.
- SHOULD follow PEP 20: readability counts; explicit is better than implicit; simple is better than complex; errors should not pass silently.
- SHOULD use stable Python 3.11 features when they make code clearer or safer.
- SHOULD prefer standard-library APIs before adding dependencies.
- SHOULD make the smallest coherent change and avoid unrelated modernization.
- AVOID adding abstractions, base classes, factories, decorators, metaclasses, async APIs, or dependency injection solely because they might be useful later.
- NEVER introduce Python 2 compatibility idioms or obsolete Python 3.5-era workarounds in new Python 3.11 code.

## Classification Meanings

| Level | Meaning |
|---|---|
| MUST | Required for correctness, safety, language contracts, or strong platform guarantees. |
| SHOULD | Recommended default; deviate when there is a concrete reason. |
| CONSIDER | Useful technique whose value depends heavily on context. |
| AVOID | Usually produces worse code; use only with a specific justification. |
| NEVER | Essentially prohibited in normal application code for this Python baseline. |

## Always-Loaded Baseline

- Prefer clear names, small functions, straightforward control flow, and local reasoning.
- Use 4-space indentation and PEP 8 whitespace/import/naming conventions unless local code consistently differs.
- Use `is` / `is not` for `None` and other singletons.
- Prefer `pathlib.Path` for new path-oriented code, while interoperating with existing `os.PathLike` and string paths.
- Use `with` and context managers for resources.
- Catch specific exceptions; do not hide errors silently.
- Prefer `dataclass(frozen=True)` or immutable built-in containers for simple value objects when mutation is not needed.
- Prefer type hints on public boundaries and non-obvious data shapes; do not make annotations noisier than the code they clarify.
- Keep concurrency explicit: do not mix blocking I/O into event loops or assume shared mutable state is safe.

## Non-Standards

This skill refuses to universalize these choices:

- Formatter choice, including Black, Ruff format, autopep8, or yapf.
- Exact maximum line length beyond PEP 8 as a baseline and repository convention as authority.
- Linter, type checker, package manager, virtual environment manager, or build backend choice.
- Testing framework choice, including pytest versus unittest.
- Project architecture, folder layout, service layering, dependency injection style, or domain model pattern.
- Web framework, ORM, serializer, task queue, data-science stack, cloud provider, or deployment model.
- Mandatory docstrings for every private helper.
- Blanket rules for single versus double quotes beyond consistency and readability.

## Reference Guide

| Reference | Use When |
|---|---|
| [Language And Design](./references/language-and-design.md) | Modules, APIs, imports, naming, functions, classes, inheritance, pattern matching, comments, docstrings. |
| [Types And Data](./references/types-and-data.md) | Type hints, dataclasses, collections, immutability, equality, strings, numbers, dates, encodings. |
| [Errors And Resources](./references/errors-and-resources.md) | Exceptions, exception chaining, context managers, cleanup, logging boundaries, validation. |
| [Concurrency](./references/concurrency.md) | `asyncio`, threads, processes, cancellation, locks, shared state, blocking hazards. |
| [I/O And Platform](./references/io-and-platform.md) | Files, paths, subprocesses, environment, serialization boundaries, standard-library APIs. |
| [Code Quality](./references/code-quality.md) | Testability, performance, security, imports, style, comments, maintainability. |
| [Legacy And Anti-Patterns](./references/legacy-and-anti-patterns.md) | Obsolete idioms, Python 2 leftovers, dynamic execution, overbroad abstractions. |
| [Agent Behaviour](./references/agent-behaviour.md) | AI-specific constraints, modernization limits, composability, repository override rules. |

## Sources

- PEP 8: Style Guide for Python Code.
- PEP 20: The Zen of Python.
- PEP 257: Docstring Conventions.
- Python 3.11 documentation: Language Reference and Standard Library.
- Python 3.11 What's New: stable 3.11 features and deprecations.
- PEP 484, PEP 526, PEP 585, PEP 604, PEP 634-636, PEP 654, PEP 655, PEP 673, PEP 675, PEP 678, PEP 680.

## Workflow

1. Identify whether the task is language-level Python work or belongs to a framework/tool overlay.
2. Preserve local conventions first, then apply this skill where the repository is silent.
3. Load only the relevant reference files.
4. Classify proposed guidance as MUST, SHOULD, CONSIDER, AVOID, or NEVER.
5. Prefer the smallest clear change that preserves behavior.
6. Avoid unrelated modernization, dependency additions, and speculative abstractions.
