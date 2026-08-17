Absolutely. I’d treat this as a **standards catalogue first**, before we turn any of it into an agent skill. The goal is to separate near-universal Java guidance from taste, context-dependent design choices, and rules that an AI agent should actively avoid violating.

Below is a first-pass classification for **vanilla Java 21**.

## Classification meanings

| Level        | Meaning                                                              |
| ------------ | -------------------------------------------------------------------- |
| **MUST**     | Required for correctness, safety, or a strong Java contract.         |
| **SHOULD**   | Recommended default; deviate when there is a concrete reason.        |
| **CONSIDER** | Useful technique whose value depends heavily on context.             |
| **AVOID**    | Usually produces worse Java; use only with a specific justification. |
| **NEVER**    | Essentially prohibited in normal application code.                   |

---

# 1. General design

### MUST

* Preserve existing externally observable behavior unless the task explicitly changes it.
* Keep class invariants valid.
* Make ownership and lifecycle of resources unambiguous.
* Respect contracts defined by implemented interfaces and overridden methods.

### SHOULD

* Prefer simple, obvious solutions over clever ones.
* Prefer cohesive classes and methods.
* Minimize coupling between unrelated concepts.
* Encapsulate implementation details.
* Keep public APIs as small as practical.
* Prefer composition over inheritance.
* Make dependencies explicit.
* Prefer domain terminology in names and APIs.
* Avoid speculative functionality.

### CONSIDER

* Introduce an abstraction when multiple concrete implementations or meaningful substitution actually exist.
* Introduce a value object when it removes primitive/string ambiguity.
* Split a class when it contains unrelated responsibilities.

### AVOID

* Premature abstraction.
* Deep inheritance hierarchies.
* Pattern-heavy implementations for simple problems.
* Creating additional layers simply because an architectural pattern permits them.

---

# 2. Java 21 language features

### SHOULD

* Use modern Java syntax where it improves clarity.
* Prefer switch expressions when a switch calculates a value.
* Use pattern matching for `instanceof` instead of explicit casts.
* Use exhaustive switch handling for closed sets of alternatives.
* Prefer records for simple immutable data carriers where record semantics are appropriate.
* Prefer enums for fixed sets of named values.

### CONSIDER

* Sealed classes/interfaces for deliberately closed hierarchies.
* Record patterns where destructuring makes code easier to understand.
* Text blocks for genuinely multiline text.
* `var` when the inferred type is immediately obvious.

### AVOID

* Writing Java 8-style boilerplate merely out of habit when Java 21 has a clearer equivalent.
* Using `var` when it hides important type information.
* Pattern matching simply to make code appear modern.

### NEVER

* Use preview language features in production code unless the project explicitly opts into them.

---

# 3. Immutability and state

### MUST

* Protect mutable internal state from unintended external mutation.
* Avoid exposing mutable collections directly when callers are not meant to modify internal state.

### SHOULD

* Prefer immutable objects.
* Declare fields `final` where reassignment is unnecessary.
* Minimize shared mutable state.
* Establish valid object state during construction.
* Prefer immutable collection snapshots at boundaries where mutation isn't intended.
* Keep mutation local and obvious.

### CONSIDER

* Records for immutable value-oriented types.
* Defensive copies when passing mutable objects across ownership boundaries.

### AVOID

* Setter-heavy designs with no genuine need for mutability.
* Mutable static state.
* Objects that are valid only after a particular sequence of setters has been called.

---

# 4. Classes and interfaces

### MUST

* Follow inheritance contracts when overriding behavior.
* Use the narrowest visibility compatible with the API requirement.

### SHOULD

* Prefer composition over inheritance.
* Keep implementation classes private/package-private when outside access isn't required.
* Design interfaces around meaningful capabilities or contracts.
* Keep inheritance shallow.
* Make classes `final` when extension would violate their intended design and extensibility isn't part of the contract.

### CONSIDER

* Static factory methods when construction intent benefits from a meaningful name.
* Builders for complex object construction.
* Sealed hierarchies for finite type systems.

### AVOID

* An interface for every implementation.
* Abstract base classes created solely for anticipated reuse.
* Public APIs that expose implementation details.
* Empty marker interfaces without a meaningful reason.

---

# 5. Records

### SHOULD

* Use records for transparent value/data carriers when their semantics match the problem.
* Validate record invariants in the compact constructor where necessary.
* Treat record components as part of the public API.

### CONSIDER

* Records for domain value objects.

### AVOID

* Records for heavily stateful entities.
* Records when component identity and structural equality do not match the domain.
* Records purely to reduce boilerplate when normal class semantics are actually needed.

---

# 6. Enums and sealed types

### SHOULD

* Prefer enums over strings for known finite values.
* Put behavior on enums where it naturally belongs.

### CONSIDER

* Sealed interfaces/classes for closed domain alternatives.
* Exhaustive pattern-switch handling over sealed hierarchies.

### AVOID

* Giant enums acting as miscellaneous global registries.
* String comparisons representing what is really an enumerated domain concept.

---

# 7. Null handling

### MUST

* Never return `null` from a method declared to return `Optional`.
* Clearly distinguish required values from optional values.
* Handle possible `null` values deliberately rather than relying on accidental `NullPointerException`s.

### SHOULD

* Prefer non-null references as the normal contract.
* Validate required arguments near the boundary.
* Use `Objects.requireNonNull()` where it communicates an invariant clearly.
* Return empty collections rather than `null` collections.

### AVOID

* Passing `null` as an implicit signal or command.
* Returning `null` where absence is a normal part of the API.

### NEVER

* Catch `NullPointerException` as ordinary control flow.

---

# 8. Optional

### SHOULD

* Use `Optional<T>` primarily for return values where absence is expected and meaningful.
* Use `orElseGet()` when constructing the fallback is expensive or side-effectful.
* Prefer `map`, `flatMap`, `filter`, etc. when they genuinely improve clarity.

### CONSIDER

* Straightforward `isPresent()`/`isEmpty()` logic when it is clearer than a functional pipeline.

### AVOID

* `Optional` fields in ordinary domain objects.
* `Optional` parameters.
* Collections of `Optional` unless the semantics genuinely require them.
* Long Optional pipelines that obscure normal control flow.

### NEVER

* Return `null` instead of `Optional.empty()`.
* Call `Optional.get()` without establishing that a value exists.

---

# 9. Collections

### MUST

* Use generic collection types rather than raw types.
* Respect collection contracts concerning mutability, ordering and uniqueness.

### SHOULD

* Expose APIs using interfaces such as `List`, `Set` and `Map`.
* Select the collection based on required semantics.
* Return empty collections instead of `null`.
* Use `List.of`, `Set.of`, `Map.of`, etc. for small immutable collections.
* Use `copyOf()` where an immutable snapshot is intended.
* Use `EnumSet`/`EnumMap` for enum-keyed data when appropriate.

### CONSIDER

* Java 21 sequenced collection interfaces where first/last/reversed semantics matter.
* `computeIfAbsent`, `merge`, etc. for straightforward map operations.

### AVOID

* Depending on iteration order where the type doesn't guarantee it.
* Returning an internal mutable collection.
* Choosing `List` automatically when uniqueness or lookup semantics suggest another type.

---

# 10. Generics

### MUST

* Do not use raw collection/generic types in new code.
* Keep unchecked operations isolated and justified.

### SHOULD

* Prefer compile-time type safety over casting.
* Follow PECS where applicable.
* Use bounded wildcards to make APIs appropriately flexible.

### CONSIDER

* Generic helper methods when several actual types share the same algorithm.

### AVOID

* Complex generic hierarchies without a concrete benefit.
* Generic abstractions introduced merely for hypothetical reuse.
* Wildcards that make APIs harder rather than easier to use.

### NEVER

* Blanket-suppress unchecked warnings across a class/project instead of addressing their source.

---

# 11. Strings

### MUST

* Use `.equals()` or an equivalent value comparison for String equality.

### SHOULD

* Use ordinary `+` concatenation when it is the clearest expression.
* Use `StringBuilder` for repeated string mutation, particularly inside loops.
* Use text blocks for naturally multiline content.
* Specify encoding at external boundaries where encoding forms part of the contract.

### CONSIDER

* `Locale.ROOT` for machine-readable case transformations.

### AVOID

* Manually concatenating filesystem paths.
* Creating a `StringBuilder` for every tiny concatenation.

### NEVER

* Use `==` to perform logical String equality.

---

# 12. Numbers

### MUST

* Use an appropriate numeric representation for the precision required by the domain.
* Define rounding explicitly when business rules depend upon it.

### SHOULD

* Prefer primitive numeric types unless object/null/generic semantics require boxed values.
* Use `BigDecimal` for exact decimal financial calculations.
* Prefer `BigDecimal.valueOf(double)` rather than `new BigDecimal(double)` when converting a double.

### CONSIDER

* Overflow-safe methods such as `Math.addExact()` when overflow would represent a programming/data error.

### AVOID

* Gratuitous boxing/unboxing.
* Implicit narrowing conversions.

### NEVER

* Use floating-point arithmetic where exact monetary values are required.

---

# 13. Date and time

### MUST

* Use a date/time type matching the actual semantics of the value.
* Make timezone/offset semantics explicit where they matter.

### SHOULD

* Use `java.time`.
* Use `Instant` for machine timestamps.
* Use `LocalDate` for dates without times.
* Use `Duration` for elapsed time.
* Use `Clock` where the current time must be controllable in tests.
* Use `DateTimeFormatter` for formatting/parsing.

### CONSIDER

* `OffsetDateTime` or `ZonedDateTime` where offset/zone semantics are relevant.

### AVOID

* Scattered direct calls to `now()` in core business logic when time is an input to the behavior.
* Converting between date/time types without documenting the intended semantics.

### NEVER

* Introduce `Date` or `Calendar` into new Java 21 code without interoperability requirements.

---

# 14. Equality and hashing

### MUST

* Override `hashCode()` whenever `equals()` is overridden.
* Preserve the `equals()` contract.
* Avoid mutating fields involved in hashing while the object is being used as a key/set member.

### SHOULD

* Model equality according to domain semantics.
* Prefer records where their generated structural equality exactly matches the required semantics.

### AVOID

* Identity equality for value objects.
* Including volatile/mutable operational state in value equality.

### NEVER

* Override `equals()` without a compatible `hashCode()` implementation.

---

# 15. `toString()`

### SHOULD

* Make diagnostic representations useful.
* Include identifying/contextual state where appropriate.

### AVOID

* Huge recursive representations.
* Expensive work inside `toString()`.

### NEVER

* Expose passwords, credentials, tokens or other secrets through `toString()`.

---

# 16. Exceptions

### MUST

* Preserve the original cause when translating an exception.
* Clean up acquired resources.
* Propagate interruption correctly.
* Keep exception contracts meaningful.

### SHOULD

* Catch an exception only when the current layer can handle, translate, enrich or deliberately terminate because of it.
* Include useful context in exception messages.
* Create domain exceptions when they add meaningful information.
* Use try-with-resources.

### CONSIDER

* Checked exceptions where callers can reasonably recover and the contract benefits from expressing this.
* Unchecked exceptions where recovery is not reasonably expected.

### AVOID

* `catch (Exception)` outside intentional application boundaries.
* Large custom exception hierarchies.
* Exception-driven normal control flow.
* Repeatedly logging and rethrowing the same exception at every layer.

### NEVER

* Silently swallow an exception.
* Catch `Throwable` in ordinary application logic.
* Use an empty `catch` block.

---

# 17. Resource management

### MUST

* Close owned resources.
* Do not close resources owned by another component unless explicitly part of the contract.

### SHOULD

* Use try-with-resources with `AutoCloseable`.
* Keep acquisition and cleanup ownership clear.
* Ensure executor services and other lifecycle resources have an explicit shutdown strategy.

### AVOID

* Manual `finally` cleanup when try-with-resources handles the requirement.
* Relying on garbage collection for timely resource cleanup.

### NEVER

* Use finalization as a resource management strategy.

---

# 18. Streams

### MUST

* Avoid interfering with a stream's data source during processing unless explicitly supported.
* Do not reuse an already-consumed stream.

### SHOULD

* Use streams for clear transformations, filtering and aggregation.
* Keep stream functions stateless/non-interfering where possible.
* Extract complicated pipeline operations into meaningfully named methods.

### CONSIDER

* A traditional loop whenever it is clearer.
* Primitive streams for numeric operations.

### AVOID

* Side effects inside `map`, `filter`, etc.
* Streams for deeply imperative workflows.
* Giant pipelines.
* Nested stream constructs that are difficult to reason about.
* Collecting intermediate lists unnecessarily.

### NEVER

* Treat "stream" as automatically superior to a loop.

---

# 19. Parallel streams

### CONSIDER

* Parallel streams only after establishing that the operation is safe, sufficiently large and actually benefits.

### AVOID

* Parallel streams in request-handling/business code without measurement.
* Parallelizing workloads that contend on shared mutable state.
* Parallel streams around blocking I/O.

### NEVER

* Add `.parallel()` merely as a performance optimization without evidence.

---

# 20. Lambdas

### SHOULD

* Keep lambdas short and comprehensible.
* Prefer standard functional interfaces where they accurately describe the operation.
* Use method references where they improve readability.

### CONSIDER

* A named method instead of a non-trivial lambda.
* A custom functional interface when the domain concept deserves a name.

### AVOID

* Large multiline lambdas.
* Stateful lambdas.
* Functional transformations that obscure straightforward imperative logic.

---

# 21. Concurrency

### MUST

* Correctly synchronize access to shared mutable state.
* Respect Java Memory Model visibility requirements.
* Preserve interruption unless intentionally consumed at a defined boundary.
* Manage executor lifecycle.

### SHOULD

* Minimize shared mutable state.
* Prefer immutable data exchanged between tasks.
* Prefer `java.util.concurrent` abstractions over low-level coordination.
* Prefer concurrent collections where they match the problem.
* Keep lock scope small.

### CONSIDER

* Atomic classes for true atomic-state problems.
* Explicit locks when they provide semantics unavailable through simpler synchronization.

### AVOID

* Blocking external calls while holding locks.
* Nested lock acquisition.
* Manual low-level thread coordination.
* Shared mutable collections protected by ad hoc synchronization where a concurrent abstraction suffices.

### NEVER

* Swallow `InterruptedException`.
* Assume `volatile` makes compound operations atomic.

---

# 22. Virtual threads

### SHOULD

* Consider virtual threads for high-concurrency workloads dominated by blocking I/O.
* Write straightforward blocking code where virtual threads provide sufficient scalability.
* Constrain the scarce resource rather than arbitrarily pooling virtual threads.

### CONSIDER

* `Executors.newVirtualThreadPerTaskExecutor()` for independent blocking tasks.

### AVOID

* Treating virtual threads as a CPU-performance feature.
* Replacing every platform thread blindly.
* ThreadLocal-heavy designs when extremely large virtual-thread counts are expected.

### NEVER

* Create a fixed-size pool of virtual threads simply because platform threads were traditionally pooled.

This last rule may need nuance in the final skill: sometimes concurrency itself needs bounding, but the thing being bounded should ordinarily be the constrained resource/workload rather than virtual-thread reuse.

---

# 23. Filesystem and I/O

### MUST

* Correctly close streams/resources.
* Treat untrusted paths as untrusted input.

### SHOULD

* Prefer `Path` and `Files`.
* Use `Path.resolve()` instead of string concatenation.
* Stream large data instead of unnecessarily loading it fully into memory.
* Be explicit about encoding where it is part of the interface.

### AVOID

* New code based primarily on legacy `File`.
* Assuming Unix or Windows separators.
* Loading arbitrarily large input using convenience APIs without considering memory.

---

# 24. Method design

### SHOULD

* Make a method perform one coherent operation.
* Keep parameters meaningful and manageable.
* Use guard clauses where they meaningfully reduce nesting.
* Keep abstraction levels coherent.
* Name methods according to intent.
* Keep side effects clear.

### CONSIDER

* Parameter objects where parameters represent one conceptual group.
* Extracting a method where the extracted operation deserves a meaningful name.

### AVOID

* Boolean flag arguments such as:

```java
saveCustomer(customer, true, false);
```

* Deep nesting.
* Very long parameter lists.
* Methods whose behavior changes radically depending on unrelated flags.

### NEVER

* Enforce arbitrary method-size rules such as "all methods must be fewer than 20 lines."

---

# 25. Naming

### MUST

* Follow Java identifier conventions unless the existing project intentionally defines another standard.

### SHOULD

* `UpperCamelCase` for types.
* `lowerCamelCase` for methods/variables.
* `UPPER_SNAKE_CASE` for constants.
* Lowercase package names.
* Name things for purpose rather than implementation.
* Use predicate-like names for boolean methods/variables.

### AVOID

* Unexplained abbreviations.
* Hungarian notation.
* Names such as `data`, `obj`, `thing`, `manager`, `helper` when a precise concept exists.
* Single-letter names outside very small, conventional scopes.

---

# 26. Comments and documentation

### MUST

* Keep comments accurate when changing related code.

### SHOULD

* Explain reasoning, constraints and non-obvious decisions.
* Document public API contracts where the code alone doesn't communicate them sufficiently.
* Document thread-safety requirements where relevant.

### AVOID

* Comments that repeat the code.
* Large historical comments.
* Commented-out implementation.
* Javadoc added mechanically to obvious getters/setters.

### NEVER

* Leave generated comments that claim behavior the implementation doesn't actually guarantee.

---

# 27. Packages

### SHOULD

* Keep packages cohesive.
* Maintain sensible dependency direction.
* Keep package visibility narrow.
* Package related domain concepts together where practical.

### CONSIDER

* Package-by-feature/domain rather than purely package-by-technical-layer.

### AVOID

* Giant `util`, `common`, `misc`, or `helpers` dumping-ground packages.
* Cyclic package dependencies.

---

# 28. Java modules / JPMS

### CONSIDER

* JPMS when strong module boundaries, distribution or encapsulation genuinely benefit the application.

### AVOID

* Introducing JPMS solely because the runtime supports it.
* Massive `opens`/`exports` declarations that eliminate its encapsulation benefit.

This should intentionally remain low-priority in the skill.

---

# 29. Validation and defensive programming

### MUST

* Reject invalid inputs where accepting them would violate a contract/invariant.

### SHOULD

* Validate at boundaries.
* Fail early when an invariant cannot be maintained.
* Keep error messages useful.
* Trust already-validated internal representations where appropriate.

### AVOID

* Re-validating every internal value repeatedly.
* Silently correcting invalid data without a domain requirement.
* Defensive code that masks programming defects.

---

# 30. Logging

### MUST

* Never log secrets/credentials.

### SHOULD

* Log operationally meaningful information.
* Preserve exception information when logging failures.
* Include enough context to diagnose the event.

### AVOID

* `System.out.println()` as application logging.
* Logging an exception at every layer through which it propagates.
* Huge objects or entire request payloads without justification.

Notice that this doesn't mandate SLF4J or another library.

---

# 31. Security

### MUST

* Treat externally supplied data as untrusted.
* Use secure APIs for security-sensitive operations.
* Prevent secrets from entering source code or logs.

### SHOULD

* Use `SecureRandom` when unpredictability matters.
* Validate user-controlled filesystem paths.
* Keep error responses from leaking sensitive implementation details.
* Prefer established cryptographic primitives.

### AVOID

* Native process execution when a safer Java API solves the problem.
* Deserialization mechanisms that instantiate arbitrary user-controlled object graphs.

### NEVER

* Implement home-grown cryptography for security-sensitive functionality.
* Hard-code production credentials.

---

# 32. Native Java serialization

### SHOULD

* Prefer explicit serialization/interchange mechanisms for new designs.

### AVOID

* Adding `Serializable` merely "in case it is needed later."
* Native serialization for persistence formats or service contracts.

### NEVER

* Deserialize arbitrary untrusted native Java serialization streams.

---

# 33. Reflection

### SHOULD

* Prefer ordinary typed Java APIs where possible.

### CONSIDER

* Reflection in infrastructure/tooling where runtime metadata genuinely requires it.

### AVOID

* Reflection inside ordinary business logic.
* Bypassing visibility/encapsulation through reflection.
* Reflection as a substitute for a proper abstraction.

---

# 34. Annotations

### SHOULD

* Use annotations where metadata naturally belongs on the program element.

### CONSIDER

* Custom annotations where several consumers genuinely need declarative metadata.

### AVOID

* Building annotation-driven mini-frameworks for simple behavior.
* Hiding substantial application control flow behind custom annotations.

---

# 35. Performance

### SHOULD

* Choose suitable algorithms and data structures.
* Measure performance before making non-obvious optimizations.
* Pay attention to complexity on potentially large collections.
* Keep obvious unnecessary repeated work out of loops.

### CONSIDER

* Allocation/boxing optimizations in demonstrated hot paths.
* Specialized data structures where profiling supports them.

### AVOID

* Micro-optimizing normal business code.
* Sacrificing maintainability for theoretical speed.
* Optimizing based solely on intuition.

### NEVER

* Claim a performance improvement without evidence when the change makes the implementation meaningfully more complex.

---

# 36. Testability

Even though the testing framework belongs elsewhere, these design standards belong here.

### SHOULD

* Make behavior deterministic where possible.
* Keep external effects at clear boundaries.
* Make dependencies explicit.
* Treat clocks/random generators/external systems as controllable dependencies when business behavior depends upon them.
* Test through meaningful APIs.

### AVOID

* Global mutable state.
* Private-method testing.
* Relaxing production encapsulation solely for tests.
* Designing everything around mocking.

---

# 37. Legacy Java APIs and practices

### SHOULD

Prefer modern equivalents in new code.

### AVOID

* `Vector`
* `Hashtable`
* `Stack`
* `Enumeration`
* `Date`
* `Calendar`
* `StringBuffer` when synchronization isn't required
* raw types
* anonymous classes where lambdas clearly suffice
* manual resource cleanup
* old `instanceof` + cast boilerplate

### NEVER

* Finalizers for resource management.
* Introduce known-obsolete APIs into greenfield code without an interoperability requirement.

---

# 38. Third-party dependencies

This is especially important for the skill.

### SHOULD

* Prefer JDK functionality when it cleanly solves a modest problem.
* Follow the repository's established dependency policy.

### CONSIDER

* A dependency when it significantly reduces complexity or risk.

### AVOID

* Pulling in a library for a trivial operation available in the JDK.
* Reimplementing a complex well-solved problem merely to avoid a reasonable dependency.

So the rule should **not** simply be "always use the JDK."

---

# 39. Agent-specific change discipline

This is probably essential.

### MUST

* Respect existing repository conventions unless explicitly instructed otherwise.
* Limit changes to the requested scope.
* Preserve API compatibility unless the requirement explicitly changes it.
* Keep builds/tests compilable after the change where reasonably possible.

### SHOULD

* Produce the smallest coherent implementation.
* Reuse existing abstractions where they fit.
* Follow existing naming/package structure.
* Identify contradictions between the requested implementation and existing code instead of silently inventing a new convention.

### AVOID

* Opportunistic refactoring unrelated to the task.
* Reformatting unrelated files.
* Adding dependencies unnecessarily.
* Creating unused extension points.
* Generating placeholder abstractions for hypothetical future requirements.
* Modernizing unrelated code merely because a newer Java feature exists.

### NEVER

* Invent architectural requirements not present in the task/repository.
* Change public behavior silently.
* Suppress compiler warnings simply to produce a clean build.

---

# 40. AI-specific overengineering guardrails

I'd make these highly visible.

### SHOULD

* Prefer existing code patterns over introducing new patterns.
* Use the simplest construct that expresses the requirement.
* Delete obsolete code when the requested change genuinely replaces it.

### AVOID

* Interface + abstract base + concrete implementation when one class suffices.
* Builders for tiny records/classes.
* Factories that merely call constructors.
* Wrapper classes with no domain semantics.
* Utility classes containing one trivial method.
* Excessive comments.
* Excessive validation deep inside trusted code.
* Premature caching.
* Premature concurrency.
* Premature asynchronous APIs.
* Design patterns added merely for architectural appearance.

### NEVER

* Generate code purely because "it might be needed later."

---

# Areas where I would deliberately **not** declare a universal rule

These are places where Java developers frequently turn preferences into "standards."

| Topic                                  | Why we shouldn't dictate it        |
| -------------------------------------- | ---------------------------------- |
| Tabs vs spaces                         | Formatter/project concern          |
| Exact line length                      | Repository concern                 |
| Exact method length                    | Context dependent                  |
| Exact class length                     | Context dependent                  |
| Checked vs unchecked exceptions        | Depends on API semantics           |
| Interface for every service            | Not good vanilla-Java practice     |
| Every class `final`                    | Too absolute                       |
| Always use `var`                       | Style preference                   |
| Never use `var`                        | Equally arbitrary                  |
| Always use streams                     | Wrong                              |
| Never use streams                      | Also wrong                         |
| Functional vs OO                       | Problem dependent                  |
| Static factory vs constructor          | Context dependent                  |
| Builder threshold                      | No universal number                |
| Package-by-feature vs package-by-layer | Architectural decision             |
| JPMS                                   | Deployment/architecture decision   |
| Dependency injection                   | Framework/application architecture |
| Specific logging library               | Not vanilla Java                   |
| Specific testing library               | Separate concern                   |
| Maven vs Gradle                        | Build concern                      |
| Formatting tool                        | Repository concern                 |

---

# What I'd promote to the top of the eventual skill

Out of everything above, these are the rules I think an AI coding agent needs to encounter **before it starts writing anything**:

1. **Target Java 21.**
2. **Do not introduce preview features unless explicitly requested.**
3. **Prefer simple, idiomatic Java over clever abstractions.**
4. **Follow existing repository conventions.**
5. **Make the smallest coherent change required.**
6. **Do not introduce dependencies unnecessarily.**
7. **Prefer immutable state where practical.**
8. **Use modern Java 21 features where they genuinely improve the design.**
9. **Don't create interfaces, builders, factories or layers speculatively.**
10. **Prefer explicit domain semantics over primitives/strings when the distinction matters.**
11. **Use exceptions for exceptional conditions and never silently swallow them.**
12. **Use `java.time`, modern collections and try-with-resources.**
13. **Use streams only when they make the operation clearer.**
14. **Minimize shared mutable state and treat concurrency deliberately.**
15. **Use virtual threads for appropriate blocking concurrency, not as a generic speed trick.**
16. **Do not modernize or refactor unrelated code.**
17. **Preserve contracts and behavior unless explicitly changing them.**

That gives us a useful distinction between the **catalogue of Java knowledge** and the much smaller **behavioral policy an agent should constantly keep in working memory**.

The next refinement I'd make is to split this catalogue into three physical parts for the future skill:

```text
java-standards/
├── SKILL.md                  # Short agent operating rules
└── references/
    ├── language-and-design.md
    ├── collections-and-types.md
    ├── errors-and-resources.md
    ├── concurrency.md
    ├── io-time-and-numbers.md
    └── code-quality.md
```

That would keep `SKILL.md` small enough to be useful to Claude, Copilot and OpenCode without dumping an enormous Java style manual into context every time, while allowing the agent to consult detailed rules only when they're relevant.
