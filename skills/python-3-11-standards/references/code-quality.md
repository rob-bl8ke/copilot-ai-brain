# Code Quality

Use when improving readability, maintainability, style, testing seams, performance, security, or general correctness.

## MUST

- Preserve observable behavior unless the task asks for a behavior change.
- Keep comments accurate when changing nearby code.
- Keep generated code syntactically valid for Python 3.11.
- Avoid security regressions: do not introduce unsafe eval, shell injection, secret leakage, or unsafe deserialization.

## SHOULD

- Prefer readability over cleverness; code is read more often than written.
- Follow PEP 8 layout, whitespace, import grouping, and naming where local convention is silent.
- Use implicit line continuation inside parentheses, brackets, and braces instead of backslashes.
- Use f-strings for readable interpolation in Python 3.11, except where templates, logging laziness, or localization require another form.
- Keep branch conditions and comprehensions readable; expand into loops when logic becomes dense.
- Prefer `enumerate`, `zip`, `any`, `all`, `sum`, `min`, `max`, and comprehensions when they make intent clearer.
- Design for testability by isolating clock, randomness, filesystem, network, and process effects behind narrow boundaries.
- Prefer deterministic functions and explicit dependencies over hidden global state.
- Choose algorithms and data structures deliberately before micro-optimizing.
- Use standard-library data structures such as `deque`, `Counter`, `defaultdict`, `heapq`, `bisect`, and `functools.lru_cache` when they directly fit the problem.

## CONSIDER

- Use `functools.cache` or `lru_cache` only for pure or effectively pure functions with bounded, understood input growth.
- Use generators for streaming data and memory efficiency.
- Use `itertools` for clear iterator pipelines, but stop when readability suffers.
- Use doctest-style examples in docstrings only when examples are stable and helpful.

## AVOID

- Large rewrites to satisfy style in unrelated code.
- Premature caching, vectorization, multiprocessing, async conversion, or custom data structures.
- Comments that restate obvious code.
- Dense one-liners, compound statements separated by semicolons, and multi-clause statements on one line.
- Broad mutation of module-level state.
- Hidden imports inside functions unless needed to avoid cycles, reduce startup cost, or isolate optional dependencies.

## NEVER

- Use `eval` or `exec` on untrusted input.
- Use `assert` for runtime validation that must run in optimized mode.
- Depend on hash iteration order for security or externally visible ordering unless the ordering contract is explicitly that of insertion-ordered `dict`.

## Agent Guardrails

- Do not add new tools, dependencies, or repository-wide formatting from this skill alone.
- Use existing tests and commands if present; do not invent a test framework.
- Prefer a small direct fix over generalized infrastructure.
