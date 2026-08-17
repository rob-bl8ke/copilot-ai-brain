---
name: java-21-standards
description: Use when writing, reviewing, refactoring, or modernizing vanilla Java 21 code. Applies Java 21 language, design, immutability, collections, null handling, exceptions, resources, concurrency, virtual threads, I/O, security, performance, and AI-agent change-discipline standards while avoiding speculative abstractions and unrelated modernization. Covers vanilla Java only — for Spring Boot-specific standards use java-21-springboot-standards.
---

# Java 21 Standards

Apply pragmatic vanilla Java 21 standards when editing or reviewing Java code. Keep the detailed standards catalogue out of working context until a section is relevant.

## Operating Rules

Keep these rules active before writing code:

1. Target Java 21.
2. Do not introduce preview features unless explicitly requested.
3. Prefer simple, idiomatic Java over clever abstractions.
4. Follow existing repository conventions.
5. Make the smallest coherent change required.
6. Do not introduce dependencies unnecessarily.
7. Prefer immutable state where practical.
8. Use modern Java 21 features where they genuinely improve the design.
9. Do not create interfaces, builders, factories, or layers speculatively.
10. Prefer explicit domain semantics over primitives/strings when the distinction matters.
11. Use exceptions for exceptional conditions and never silently swallow them.
12. Use `java.time`, modern collections, and try-with-resources.
13. Use streams only when they make the operation clearer.
14. Minimize shared mutable state and treat concurrency deliberately.
15. Use virtual threads for appropriate blocking concurrency, not as a generic speed trick.
16. Do not modernize or refactor unrelated code.
17. Preserve contracts and behavior unless explicitly changing them.

## Classification Meanings

| Level | Meaning |
|---|---|
| MUST | Required for correctness, safety, or a strong Java contract. |
| SHOULD | Recommended default; deviate when there is a concrete reason. |
| CONSIDER | Useful technique whose value depends heavily on context. |
| AVOID | Usually produces worse Java; use only with a specific justification. |
| NEVER | Essentially prohibited in normal application code. |

## Always-Loaded Standards

### General Design

Use when making any Java change.

MUST:

- Preserve existing externally observable behavior unless the task explicitly changes it.
- Keep class invariants valid.
- Make ownership and lifecycle of resources unambiguous.
- Respect contracts defined by implemented interfaces and overridden methods.

SHOULD:

- Prefer simple, obvious solutions over clever ones.
- Prefer cohesive classes and methods.
- Minimize coupling between unrelated concepts.
- Encapsulate implementation details.
- Keep public APIs as small as practical.
- Prefer composition over inheritance.
- Make dependencies explicit.
- Prefer domain terminology in names and APIs.
- Avoid speculative functionality.

CONSIDER:

- Introduce an abstraction when multiple concrete implementations or meaningful substitution actually exist.
- Introduce a value object when it removes primitive/string ambiguity.
- Split a class when it contains unrelated responsibilities.

AVOID:

- Premature abstraction.
- Deep inheritance hierarchies.
- Pattern-heavy implementations for simple problems.
- Creating additional layers simply because an architectural pattern permits them.

### Java 21 Language Features

Use when choosing syntax or deciding whether to modernize code.

SHOULD:

- Use modern Java syntax where it improves clarity.
- Prefer switch expressions when a switch calculates a value.
- Use pattern matching for `instanceof` instead of explicit casts.
- Use exhaustive switch handling for closed sets of alternatives.
- Prefer records for simple immutable data carriers where record semantics are appropriate.
- Prefer enums for fixed sets of named values.

CONSIDER:

- Sealed classes/interfaces for deliberately closed hierarchies.
- Record patterns where destructuring makes code easier to understand.
- Text blocks for genuinely multiline text.
- `var` when the inferred type is immediately obvious.

AVOID:

- Writing Java 8-style boilerplate merely out of habit when Java 21 has a clearer equivalent.
- Using `var` when it hides important type information.
- Pattern matching simply to make code appear modern.

NEVER:

- Use preview language features in production code unless the project explicitly opts into them.

### 39. Agent-specific change discipline

MUST:

- Respect existing repository conventions unless explicitly instructed otherwise.
- Limit changes to the requested scope.
- Preserve API compatibility unless the requirement explicitly changes it.
- Keep builds/tests compilable after the change where reasonably possible.

SHOULD:

- Produce the smallest coherent implementation.
- Reuse existing abstractions where they fit.
- Follow existing naming/package structure.
- Identify contradictions between the requested implementation and existing code instead of silently inventing a new convention.

AVOID:

- Opportunistic refactoring unrelated to the task.
- Reformatting unrelated files.
- Adding dependencies unnecessarily.
- Creating unused extension points.
- Generating placeholder abstractions for hypothetical future requirements.
- Modernizing unrelated code merely because a newer Java feature exists.

NEVER:

- Invent architectural requirements not present in the task/repository.
- Change public behavior silently.
- Suppress compiler warnings simply to produce a clean build.

### AI-specific overengineering guardrails

SHOULD:

- Prefer existing code patterns over introducing new patterns.
- Use the simplest construct that expresses the requirement.
- Delete obsolete code when the requested change genuinely replaces it.

AVOID:

- Interface + abstract base + concrete implementation when one class suffices.
- Builders for tiny records/classes.
- Factories that merely call constructors.
- Wrapper classes with no domain semantics.
- Utility classes containing one trivial method.
- Excessive comments.
- Excessive validation deep inside trusted code.
- Premature caching.
- Premature concurrency.
- Premature asynchronous APIs.
- Design patterns added merely for architectural appearance.

NEVER:

- Generate code purely because "it might be needed later."

### Areas without universal rules

Do not impose a standard on these topics — they are project or context decisions:

| Topic | Why |
|---|---|
| Tabs vs spaces | Formatter/project concern |
| Exact line length | Repository concern |
| Exact method length | Context dependent |
| Exact class length | Context dependent |
| Checked vs unchecked exceptions | Depends on API semantics |
| Interface for every service | Not good vanilla-Java practice |
| Every class `final` | Too absolute |
| Always use `var` | Style preference |
| Never use `var` | Equally arbitrary |
| Always use streams | Wrong |
| Never use streams | Also wrong |
| Functional vs OO | Problem dependent |
| Static factory vs constructor | Context dependent |
| Builder threshold | No universal number |
| Package-by-feature vs package-by-layer | Architectural decision |
| JPMS | Deployment/architecture decision |
| Dependency injection | Framework/application architecture |
| Specific logging library | Not vanilla Java |
| Specific testing library | Separate concern |
| Maven vs Gradle | Build concern |
| Formatting tool | Repository concern |

## Section Guide

Detailed rules for sections 3 onward live in section-specific files under `references/`. Load only the relevant reference file(s).

| Section | Consider When |
|---|---|
| [3. Immutability and state](./references/03-immutability-and-state.md) | Exposing state, copying collections, designing constructors, choosing mutable vs immutable models. |
| [4. Classes and interfaces](./references/04-classes-and-interfaces.md) | Creating/extending types, choosing visibility, adding interfaces, inheritance, factories, or builders. |
| [5. Records](./references/05-records.md) | Modeling immutable data carriers or deciding whether record semantics match the domain. |
| [6. Enums and sealed types](./references/06-enums-and-sealed-types.md) | Modeling finite values, closed alternatives, or exhaustive switch handling. |
| [7. Null handling](./references/07-null-handling.md) | Designing null contracts, validating required values, or handling absence. |
| [8. Optional](./references/08-optional.md) | Returning absence from APIs or deciding whether Optional clarifies logic. |
| [9. Collections](./references/09-collections.md) | Choosing collection types, preserving mutability/order/uniqueness contracts, returning snapshots. |
| [10. Generics](./references/10-generics.md) | Designing type-safe APIs, wildcard boundaries, or suppressing unchecked operations. |
| [11. Strings](./references/11-strings.md) | Comparing strings, building text, handling encodings, paths, or locale-sensitive case. |
| [12. Numbers](./references/12-numbers.md) | Handling money, rounding, precision, boxed values, conversions, or overflow. |
| [13. Date and time](./references/13-date-and-time.md) | Choosing `java.time` types, injecting clocks, or handling zones/offsets. |
| [14. Equality and hashing](./references/14-equality-and-hashing.md) | Implementing `equals`/`hashCode`, value semantics, or key/set-member safety. |
| [15. `toString()`](./references/15-tostring.md) | Adding diagnostic output or preventing secrets/expensive recursive representations. |
| [16. Exceptions](./references/16-exceptions.md) | Translating, catching, logging, propagating, or designing exception contracts. |
| [17. Resource management](./references/17-resource-management.md) | Owning, closing, or lifecycle-managing streams, executors, or other resources. |
| [18. Streams](./references/18-streams.md) | Choosing streams vs loops, designing pipelines, or preventing side effects. |
| [19. Parallel streams](./references/19-parallel-streams.md) | Considering `.parallel()` or reviewing parallel stream safety/performance. |
| [20. Lambdas](./references/20-lambdas.md) | Choosing lambdas, method references, named methods, or functional interfaces. |
| [21. Concurrency](./references/21-concurrency.md) | Sharing mutable state, synchronization, visibility, interruption, executors, locks, or concurrent collections. |
| [22. Virtual threads](./references/22-virtual-threads.md) | Handling high-concurrency blocking I/O or deciding whether virtual threads fit. |
| [23. Filesystem and I/O](./references/23-filesystem-and-io.md) | Handling paths, streams, untrusted filesystem input, encodings, or large data. |
| [24. Method design](./references/24-method-design.md) | Changing method shape, parameters, side effects, guard clauses, or abstraction level. |
| [25. Naming](./references/25-naming.md) | Naming packages, types, methods, constants, booleans, or domain concepts. |
| [26. Comments and documentation](./references/26-comments-and-documentation.md) | Adding/updating comments, Javadocs, public contracts, or thread-safety notes. |
| [27. Packages](./references/27-packages.md) | Placing code, maintaining package cohesion, dependencies, and visibility. |
| [28. Java modules / JPMS](./references/28-java-modules-jpms.md) | Considering module boundaries, exports, opens, distribution, or strong encapsulation. |
| [29. Validation and defensive programming](./references/29-validation-and-defensive-programming.md) | Validating boundaries, rejecting bad input, preserving invariants, or avoiding defensive noise. |
| [30. Logging](./references/30-logging.md) | Logging failures, operational context, payloads, secrets, or exception propagation. |
| [31. Security](./references/31-security.md) | Handling untrusted data, credentials, cryptography, paths, process execution, or deserialization. |
| [32. Native Java serialization](./references/32-native-java-serialization.md) | Considering `Serializable`, persistence formats, service contracts, or untrusted streams. |
| [33. Reflection](./references/33-reflection.md) | Adding runtime metadata logic, tooling, infrastructure hooks, or bypassing encapsulation. |
| [34. Annotations](./references/34-annotations.md) | Adding metadata, custom annotations, or annotation-driven behavior. |
| [35. Performance](./references/35-performance.md) | Optimizing algorithms, hot paths, allocations, boxing, or complexity. |
| [36. Testability](./references/36-testability.md) | Designing deterministic behavior, dependency boundaries, clocks, randomness, or external effects. |
| [37. Legacy Java APIs and practices](./references/37-legacy-java-apis-and-practices.md) | Encountering `Vector`, `Hashtable`, `Date`, raw types, finalizers, old casts, or manual cleanup. |
| [38. Third-party dependencies](./references/38-third-party-dependencies.md) | Adding libraries, preferring JDK functionality, or avoiding trivial dependencies. |

## Workflow

1. Identify which section(s) apply to the code being changed.
2. Read only the relevant section-specific reference file(s).
3. Apply MUST and NEVER rules strictly unless the user explicitly overrides them.
4. Treat SHOULD as the default and CONSIDER as context-dependent.
5. Avoid unrelated modernization, formatting, dependency changes, or speculative abstractions.
