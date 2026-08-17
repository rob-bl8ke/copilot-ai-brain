# Concurrency

Use when changing `asyncio`, threads, processes, cancellation, locks, queues, shared state, or blocking I/O.

## MUST

- Do not call blocking I/O or CPU-heavy work directly from an event loop unless it is intentionally offloaded or bounded.
- Await coroutines or intentionally schedule tasks; un-awaited coroutines are bugs.
- Handle cancellation correctly: let `asyncio.CancelledError` propagate unless there is a specific cleanup requirement.
- Protect shared mutable state accessed by multiple threads or tasks with appropriate synchronization or confinement.
- Join, await, cancel, or otherwise account for spawned tasks and workers.
- Use process-safe and thread-safe primitives only according to their documented contracts.

## SHOULD

- Use `asyncio.run()` as the main entry point for top-level async programs.
- Use `asyncio.TaskGroup` for structured concurrency in new Python 3.11 async code.
- Use `asyncio.timeout()` for scoped timeouts in new async code.
- Prefer queues, immutable messages, or explicit ownership transfer over shared mutable state.
- Use `contextvars` for task-local context instead of thread-local state in async code.
- Use `concurrent.futures` or `asyncio.to_thread()` for blocking work that must integrate with async code.
- Use `multiprocessing` or process pools for CPU-bound parallelism when true parallel execution matters.

## CONSIDER

- Use threads for I/O-bound concurrency around blocking libraries.
- Use processes for CPU-bound work or isolation from interpreter-global state.
- Use locks, semaphores, events, and conditions sparingly and keep critical sections small.
- Use `ExceptionGroup` when concurrent operations can produce multiple independent failures.

## AVOID

- Fire-and-forget tasks without lifecycle management and error reporting.
- Mixing sync and async APIs without clear boundary functions.
- Holding locks while doing I/O, awaiting, or calling unknown user code.
- Depending on the GIL for correctness of compound operations.
- Global mutable caches shared across threads without synchronization.
- Nested event loops or calling `asyncio.run()` from inside a running event loop.

## NEVER

- Swallow cancellation in long-running tasks without re-raising after cleanup.
- Use private `asyncio` internals as application APIs.
- Assume code is thread-safe because individual built-in operations appear atomic.

## Agent Guardrails

- Do not convert synchronous code to async unless the task explicitly requires it or the surrounding API is already async.
- Do not introduce concurrency for speculative performance.
- Prefer fixing lifecycle, cancellation, and blocking hazards over adding new abstractions.
