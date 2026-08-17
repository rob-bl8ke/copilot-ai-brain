# Standards Catalogue

Use this catalogue as the starting point for discovering language-level standards. Not every language needs every section, and some languages need additional sections.

## Scope Catalogue

Document these first:

- Target language and version.
- Runtime, VM, compiler, interpreter, or platform.
- Standard library surface assumed available.
- Stable features to prefer.
- Preview, experimental, deprecated, or implementation-specific features to avoid unless requested.
- Tooling intentionally excluded from the base language skill.

## Language And Design

Catalogue guidance for:

- Idiomatic language style.
- Modules, namespaces, or packages.
- Visibility and encapsulation.
- Public API design.
- Composition versus inheritance or equivalent extension mechanisms.
- Abstraction boundaries.
- Domain modeling.
- Dependency direction.

## Types And Data

Catalogue guidance for:

- Type system strengths and weaknesses.
- Nullability or absence handling.
- Value objects, records, structs, data classes, tuples, or equivalents.
- Mutability and immutability.
- Collections and maps.
- Equality, hashing, ordering, and identity.
- Numeric precision, money, dates, times, strings, and encodings.

## Errors And Resources

Catalogue guidance for:

- Error signaling conventions.
- Exception, result, option, panic, or error-value semantics.
- Resource ownership and cleanup.
- Disposal, finalization, destructors, context managers, or try-with-resource equivalents.
- Logging versus propagation.
- Boundary validation.

## Concurrency

Catalogue guidance for:

- Native concurrency model.
- Shared mutable state hazards.
- Async, futures, promises, coroutines, fibers, threads, or event loops.
- Cancellation and interruption.
- Synchronization primitives.
- Thread-safety or task-safety contracts.
- Common deadlock, race, starvation, and blocking hazards.

## I/O And Platform

Catalogue guidance for:

- Filesystem paths.
- Streams and buffers.
- Encodings and locales.
- Network I/O.
- Process execution.
- Environment variables.
- Platform-specific behavior.

## Testing And Testability

Catalogue language-level testability guidance without mandating a specific testing framework unless the language has a dominant built-in standard.

Cover:

- Deterministic design.
- Dependency boundaries.
- Clock, randomness, and external effects.
- Pure functions where useful.
- Avoiding unnecessary global state.

## Performance And Security

Catalogue language-specific performance and security guidance:

- Algorithmic complexity.
- Allocation and copying costs.
- Reflection, dynamic execution, metaprogramming, or eval hazards.
- Serialization risks.
- Secret handling.
- Injection risks.
- Unsafe APIs.
- Cryptography boundaries.

## Legacy And Anti-Patterns

Catalogue practices that an AI agent should avoid generating:

- Deprecated APIs.
- Obsolete idioms from older language versions.
- Cargo-cult patterns.
- Overbroad abstractions.
- Excessive comments.
- Premature caching, concurrency, or async APIs.
- Dependency additions for trivial standard-library behavior.

## Agent Behaviour

Catalogue AI-specific operating constraints:

- Preserve repository conventions.
- Make the smallest coherent change.
- Avoid unrelated modernization.
- Preserve public behavior unless explicitly changing it.
- Avoid speculative layers, factories, builders, wrappers, interfaces, or configuration.
- Prefer standard-library features before adding dependencies.
