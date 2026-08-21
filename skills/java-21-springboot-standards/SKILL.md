---
name: java-21-springboot-standards
description: Use when writing, reviewing, refactoring, or testing Java 21 Spring Boot 3.5.11 applications. Applies Spring Boot overlay standards for auto-configuration, dependency injection, configuration properties, controllers, validation, transactions, bean lifecycle, testing scope, dependency management, observability, and Spring-specific AI anti-patterns. Complements java-21-standards when available and works standalone when it is not.
---

# Java Spring Boot Standards

Apply Spring Boot framework standards as an overlay on Java 21 code quality standards.

If `java-21-standards` is available, apply it first. If it is not available, still preserve the baseline Java principles in this file: simple Java 21, explicit dependencies, immutable state where practical, no preview features unless requested, no speculative abstractions, no unrelated modernization, and no silent behavior changes.

## Target Environment

| Concern | Standard |
|---|---|
| Java | 21 |
| Spring Boot | 3.5.11 |
| Build | Maven |
| Parent | `org.springframework.boot:spring-boot-starter-parent:3.5.11` |

Treat Spring Boot `3.5.11` as an intentional project constraint, not as a placeholder for the latest Spring Boot version.

## Operating Rules

Keep these rules active before writing code:

1. Apply `java-21-standards` first when available.
2. Target Java 21 and Spring Boot 3.5.11; never upgrade either implicitly.
3. Prefer Spring Boot conventions and auto-configuration over custom framework plumbing.
4. Use constructor injection for required dependencies; avoid field injection.
5. Keep business/domain logic ordinary Java where practical.
6. Make only objects requiring framework management Spring beans.
7. Prefer typed `@ConfigurationProperties` for related application configuration.
8. Keep controllers thin and delegate application behavior.
9. Validate external input at boundaries and preserve domain invariants internally.
10. Keep transaction boundaries around coherent application operations, not controllers.
11. Remember singleton Spring beans must not contain unsafe request-specific mutable state.
12. Load only as much Spring context as a test actually requires.
13. Let Spring Boot manage dependency versions wherever possible.
14. Use annotations only when their behavior is understood and required.
15. Do not create layers, interfaces, DTOs, mappers, or configuration classes speculatively.
16. Do not refactor unrelated Java into Spring-style code.
17. Make the smallest coherent framework-aware change.

## Agent Guardrails

These rules apply specifically to AI-agent-generated code and distil the most common Spring failure modes. Full detail in [section 39](./references/39-spring-specific-ai-anti-patterns.md) and [40](./references/40-agent-change-discipline.md).

### Never generate layer explosions

Automatically creating a full stack of:

```text
FooController
FooService
FooServiceImpl
FooRepository
FooRepositoryImpl
FooMapper
FooDto
FooEntity
FooConfiguration
FooException
FooExceptionHandler
```

for every feature is the most common AI anti-pattern with Spring. Create only what the requirement justifies.

### Never sprinkle annotations without purpose

Each of the following must solve an actual stated problem before being introduced:

* `@Transactional`
* `@Async`
* `@Cacheable`
* `@Retryable`
* interfaces
* DTOs
* mappers
* configuration classes
* Spring profiles
* event publishers

### Never touch versions or existing architecture silently

MUST NOT:
* Upgrade Spring Boot or managed dependency versions.
* Introduce a Spring abstraction merely because it exists.
* Invent a new architectural layer when one already exists.
* Override existing conventions with a different style.

MUST:
* Make the smallest Spring-aware change.
* Preserve existing bean wiring, configuration, and tests.
* Reuse existing application architecture.

## Classification Meanings

| Level | Meaning |
|---|---|
| MUST | Required for correctness, safety, or a strong Spring/Java contract. |
| SHOULD | Recommended default; deviate when there is a concrete reason. |
| CONSIDER | Useful technique whose value depends heavily on context. |
| AVOID | Usually produces worse Spring Boot code; use only with a specific justification. |
| NEVER | Essentially prohibited in normal application code. |

## Overlay Principle

This skill is additive, not a replacement for Java standards.

MUST:

- Apply `java-21-standards` first when available.
- Prefer normal Java constructs when Spring adds no useful capability.
- Follow Spring Boot conventions where they simplify framework integration.
- Respect the project's pinned Java and Spring Boot versions.

SHOULD:

- Keep framework concerns toward application/infrastructure boundaries.
- Keep domain/business logic as ordinary Java wherever practical.
- Minimize unnecessary Spring coupling.
- Let Spring manage objects that genuinely participate in application infrastructure/lifecycle.

AVOID:

- Repeating or redefining vanilla Java rules here.
- Turning every Java class into a Spring bean.
- Adding Spring annotations merely because Spring is available.

NEVER:

- Override a base Java rule solely because "this is Spring".

## Section Guide

Detailed Spring Boot rules live in section-specific files under `references/`. Load only the relevant reference file(s).

| Section | Consider When |
|---|---|
| [1. Relationship with Java standards](./references/01-relationship-with-java-21-standards.md) | Deciding whether Spring changes, complements, or leaves normal Java guidance unchanged. |
| [2. Boot conventions over manual configuration](./references/02-boot-conventions-over-manual-configuration.md) | Choosing auto-configuration, starters, managed dependencies, or custom infrastructure. |
| [3. Application entry point](./references/03-application-entry-point.md) | Creating or moving `@SpringBootApplication` and root package structure. |
| [4. Dependency injection](./references/04-dependency-injection.md) | Injecting collaborators, choosing constructor/setter/field injection, or using `ApplicationContext`. |
| [5. Spring stereotypes](./references/05-spring-stereotypes.md) | Choosing `@Component`, `@Service`, `@Repository`, `@Controller`, or `@RestController`. |
| [6. Component scanning](./references/06-component-scanning.md) | Adjusting package layout, scan boundaries, or `@ComponentScan`. |
| [7. Configuration classes](./references/07-configuration-classes.md) | Adding `@Configuration`, `@Bean`, third-party construction, or lifecycle-aware configuration. |
| [8. `@ConfigurationProperties`](./references/08-configuration-properties.md) | Binding related application configuration or replacing scattered `@Value`. |
| [9. Configuration validation](./references/09-configuration-validation.md) | Validating configuration and failing fast at startup. |
| [10. Profiles](./references/10-profiles.md) | Modeling environment/runtime differences with Spring profiles. |
| [11. Secrets and external configuration](./references/11-secrets-and-external-configuration.md) | Handling credentials, committed config, externalized settings, or deployment secrets. |
| [12. Business/domain code](./references/12-business-domain-code.md) | Deciding whether a class should stay plain Java or become Spring-managed. |
| [13. Controllers](./references/13-controllers.md) | Implementing Spring MVC controllers and HTTP boundary behavior. |
| [14. Request/response DTOs](./references/14-request-response-dtos.md) | Modeling transport contracts, records, validation, and entity exposure. |
| [15. Bean Validation](./references/15-bean-validation.md) | Applying Jakarta Bean Validation at request/configuration boundaries. |
| [16. Exception handling](./references/16-exception-handling.md) | Translating application exceptions to HTTP responses. |
| [17. `ProblemDetail`](./references/17-problemdetail.md) | Designing consistent modern API error responses. |
| [18. Transaction boundaries](./references/18-transaction-boundaries.md) | Adding `@Transactional` or defining application operation boundaries. |
| [19. Self-invocation / proxy awareness](./references/19-self-invocation-proxy-awareness.md) | Using proxy-backed features such as transactions, async, caching, or validation. |
| [20. Bean scope and state](./references/20-bean-scope-and-state.md) | Adding state to Spring beans or reviewing singleton thread-safety. |
| [21. Lifecycle](./references/21-lifecycle.md) | Managing startup, shutdown, callbacks, resources, or background work. |
| [22. Async execution](./references/22-async-execution.md) | Considering `@Async`, hidden async boundaries, or latency handling. |
| [23. Virtual threads](./references/23-virtual-threads.md) | Combining Spring Boot virtual-thread support with Java 21 virtual-thread semantics. |
| [24. Scheduling](./references/24-scheduling.md) | Using `@Scheduled`, configurable schedules, duplicate execution, or multi-instance behavior. |
| [25. Repository/data layer](./references/25-repository-data-layer.md) | Keeping persistence behind boundaries without going into JPA/JDBC details. |
| [26. HTTP clients](./references/26-http-clients.md) | Configuring outbound clients, timeouts, typed models, and downstream failure boundaries. |
| [27. Logging](./references/27-logging.md) | Applying Spring-aware logging without mandating a library. |
| [28. Actuator and observability](./references/28-actuator-and-observability.md) | Adding health, metrics, diagnostics, or management endpoints. |
| [29. Health indicators](./references/29-health-indicators.md) | Designing liveness/readiness checks and cheap health indicators. |
| [30. Dependency management](./references/30-dependency-management.md) | Editing Maven dependencies, starters, managed versions, or overrides. |
| [31. Starter selection](./references/31-starter-selection.md) | Choosing Spring Boot starters without adding broad dependencies just in case. |
| [32. Testing strategy](./references/32-testing-strategy.md) | Selecting plain unit tests, focused Spring tests, integration tests, or `@SpringBootTest`. Defers to `unit-testing`, `db-core-jpa-integration-tests`, and `db-core-e2e-tests` skills when present. |
| [33. Testcontainers](./references/33-testcontainers.md) | Using real external systems in integration tests where correctness depends on them. Defers to `db-core-jpa-integration-tests` and `db-core-e2e-tests` skills when present. |
| [34. Mocking Spring](./references/34-mocking-spring.md) | Choosing what to mock and avoiding tests coupled to Spring internals. Defers to `unit-testing` skill when present. |
| [35. Package organization](./references/35-package-organization.md) | Placing application classes and avoiding universal package architecture mandates. |
| [36. Annotation restraint](./references/36-annotation-restraint.md) | Adding annotations or reviewing annotation-heavy code. |
| [37. Framework magic versus explicit Java](./references/37-framework-magic-versus-explicit-java.md) | Deciding between Spring idioms and ordinary Java idioms. |
| [38. Framework escape hatches](./references/38-framework-escape-hatches.md) | Considering low-level APIs such as `ApplicationContext`, `BeanFactory`, or `Environment`. |
| [39. Spring-specific AI anti-patterns](./references/39-spring-specific-ai-anti-patterns.md) | Preventing generated layer explosions, speculative annotations, DTOs, mappers, events, or profiles. |
| [40. Agent change discipline](./references/40-agent-change-discipline.md) | Scoping AI-generated Spring changes, preserving versions, wiring, config, and build correctness. |

## Workflow

1. Check whether the code is Spring Boot-specific or plain Java.
2. Apply `java-21-standards` first when available; otherwise apply the baseline Java principles in this skill.
3. Identify the relevant Spring Boot section(s) from the guide.
4. Read only the relevant section-specific reference file(s).
5. Prefer Boot conventions before custom framework plumbing.
6. Preserve Java 21, Spring Boot 3.5.11, Maven, and existing project conventions unless the user explicitly changes them.
7. Avoid unrelated refactors, dependency upgrades, broad component scans, speculative layers, and annotation-driven behavior you do not need.
