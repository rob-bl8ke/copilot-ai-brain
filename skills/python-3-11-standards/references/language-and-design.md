# Language And Design

Use when changing Python modules, public APIs, imports, naming, functions, classes, comments, docstrings, or control flow.

## MUST

- Preserve public API behavior and compatibility unless the task explicitly changes it.
- Put imports at the top of the file after module docstrings and module dunders, except required `from __future__` imports.
- Keep imports explicit enough that readers and tools can determine where names come from.
- Use documented dunder methods only for their documented protocols; do not invent new `__dunder__` names.
- Use `self` for instance methods and `cls` for class methods.
- Make public versus internal interfaces clear: public names have no leading underscore; internal implementation details use a single leading underscore.
- Use `__all__` when a module intentionally defines a public export surface, especially if wildcard import behavior matters.

## SHOULD

- Follow PEP 8 naming defaults: modules and functions `lower_case_with_underscores`, classes `CapWords`, constants `UPPER_CASE_WITH_UNDERSCORES`, exceptions ending in `Error` when they represent errors.
- Prefer absolute imports unless explicit relative imports make a package-local relationship clearer.
- Keep functions focused around one responsibility and make data flow visible through parameters and return values.
- Prefer simple functions and composition over inheritance when no subclass contract is required.
- Use plain public attributes for simple data; add `@property` only when access needs logic while preserving attribute syntax.
- Use structural pattern matching when it improves clarity for structured branching; keep guards simple and avoid turning `match` into a hidden dispatch framework.
- Write docstrings for public modules, functions, classes, and methods; follow PEP 257 conventions.
- Use comments to explain non-obvious intent, constraints, or tradeoffs; keep comments synchronized with code.
- Prefer explicit control flow over dense expressions when behavior is easier to read step by step.

## CONSIDER

- Use double-leading underscores only to avoid accidental subclass attribute collisions in classes designed for inheritance.
- Use `functools.singledispatch` for type-based extension points when a real extension surface exists.
- Use `Protocol` or abstract base classes when multiple implementations genuinely share a behavioral contract.
- Use `@classmethod` alternative constructors when construction has a named domain meaning.

## AVOID

- Wildcard imports except for deliberate API re-export modules.
- Import-time side effects beyond defining constants, functions, classes, and lightweight metadata.
- Deep nesting; refactor with early returns, helper functions, or clearer data structures when nesting obscures behavior.
- `lambda` assigned directly to a name; use `def` for better tracebacks and introspection.
- Accessor/mutator methods for plain attributes when Python attribute access is sufficient.
- Metaclasses, decorators, descriptors, monkeypatching, or dynamic attribute creation without a concrete need.

## NEVER

- Mix tabs and spaces for indentation.
- Use ambiguous single-character names `l`, `O`, or `I`.
- Use `from module import *` in ordinary implementation modules.
- Change public behavior only to satisfy style guidance.

## Agent Guardrails

- Prefer local consistency over broad PEP 8 rewrites in untouched code.
- Do not rename public symbols for style unless the user requested an API-breaking change.
- Do not introduce framework patterns into language-only code.
