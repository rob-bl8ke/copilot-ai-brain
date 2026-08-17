# Legacy And Anti-Patterns

Use when reviewing old idioms, generated code, broad refactors, or suspicious patterns.

## MUST

- Keep compatibility with the repository's declared Python baseline; for this skill, new language guidance assumes Python 3.11.x.
- Treat deprecations in Python 3.11 as reasons to avoid generating new usages.
- Preserve intentional legacy behavior when modifying old code unless modernization is part of the task.

## SHOULD

- Replace Python 2 compatibility idioms in touched Python 3.11-only code when doing so is local and behavior-preserving.
- Prefer modern standard-library replacements: `pathlib` over ad hoc path strings, `importlib` over `imp`, `argparse` over `optparse`, `subprocess` over `os.system` and `popen`, `zoneinfo` over custom timezone tables when sufficient.
- Prefer `super()` without arguments in ordinary Python 3 code.
- Prefer built-in generic types and union syntax in new annotations.
- Prefer `asyncio.TaskGroup` and `asyncio.timeout` in new structured async code.

## CONSIDER

- Modernize touched code incrementally when it reduces complexity and does not broaden the change.
- Leave stable legacy modules alone if changing them would create unnecessary risk.

## AVOID

- `six`, `future`, `past`, `typing_extensions`, or compatibility shims in new Python 3.11-only code unless the repository already depends on them for other supported versions.
- `os.path` string choreography in new path-heavy code when `pathlib` is clearer.
- `datetime.utcnow()` for real instants; prefer aware UTC datetimes.
- `dict.has_key`, old-style `%` interpolation for new user-facing formatting, and manual loop counters.
- `except Exception: pass`, `bare except`, or blanket retry loops without limits and observability.
- Dynamic code generation for ordinary dispatch or configuration.
- Large class hierarchies, factory layers, and registry systems for simple local behavior.

## NEVER

- Generate Python 2 syntax or compatibility-only constructs for Python 3.11 code.
- Use deprecated `imp` APIs in new code.
- Use `asyncore`, `asynchat`, or `cgi` for new application code.
- Use `thread`/`_thread` directly when `threading` provides the needed abstraction.

## Agent Guardrails

- Do not modernize entire files just because you touched one function.
- Do not introduce `typing_extensions` for features available in Python 3.11 `typing`.
- Do not replace working framework-specific idioms without loading the relevant framework skill.
