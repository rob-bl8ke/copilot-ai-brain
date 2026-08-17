# Errors And Resources

Use when changing exceptions, validation, cleanup, context managers, logging boundaries, or resource ownership.

## MUST

- Catch specific exceptions whenever possible.
- Re-raise with bare `raise` inside an `except` block when preserving the original exception.
- Use exception chaining with `raise NewError(...) from exc` when translating exceptions and retaining cause matters.
- Use `raise NewError(...) from None` only when intentionally hiding implementation details, and preserve relevant details in the new message.
- Use `with` for files, locks, network handles, temporary resources, and other context-managed resources.
- Keep `try` blocks as narrow as practical so handlers do not catch unrelated errors.
- Do cleanup with `finally` or context managers without suppressing active exceptions accidentally.

## SHOULD

- Derive application exceptions from `Exception`, not `BaseException`.
- Design exception types around what callers can recover from or handle programmatically.
- Include actionable context in exception messages without leaking secrets.
- Use `else` on `try` statements when success-path work should not be covered by the handler.
- Use `contextlib.ExitStack` or `AsyncExitStack` when managing a dynamic number of resources.
- Use `BaseException.add_note()` in Python 3.11 to attach contextual diagnostic details when re-raising or aggregating errors.
- Use `ExceptionGroup` and `except*` when multiple independent failures can occur concurrently and callers need per-exception handling.
- Log at process, task, or boundary layers where the event can be acted on; otherwise propagate and let callers decide.

## CONSIDER

- Define small custom exception hierarchies for library-like code with stable public failure contracts.
- Use `contextlib.suppress` only when ignoring that exact exception is intentional and safe.
- Use `contextlib.nullcontext` to simplify optional context-manager paths.
- Use `warnings.warn` for deprecated behavior that remains supported.

## AVOID

- Bare `except:`; it catches `KeyboardInterrupt` and `SystemExit`.
- Broad `except Exception:` handlers unless they are at a boundary and either re-raise, translate, or report the failure.
- Silently swallowing errors to make code appear robust.
- Returning `None`, `False`, or sentinel strings for exceptional failures when callers need failure details.
- Control-flow statements such as `return`, `break`, or `continue` in `finally` blocks because they can suppress exceptions.
- Logging and re-raising the same exception at every layer.

## NEVER

- Catch `BaseException` in normal application code unless implementing a top-level runtime boundary that immediately re-raises termination signals correctly.
- Hide security, data-loss, or integrity errors merely to keep execution going.
- Rely on `__del__` for timely resource cleanup.

## Agent Guardrails

- Do not add a result/error monad or custom framework when normal exceptions fit the codebase.
- Do not change exception types on public APIs without an explicit compatibility reason.
- Preserve existing logging strategy unless the task is about observability or error reporting.
