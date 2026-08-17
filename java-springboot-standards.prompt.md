Yes. I’d make this a **strict overlay skill**:

```text
java-standards
      ↓
java-springboot-standards
```

The Spring skill should assume every rule in `java-standards` remains in force unless Spring itself provides a framework-specific mechanism that changes how the rule should be implemented. It should **never redefine basic Java style, collections, streams, `Optional`, exceptions, records, concurrency, etc.**

For this catalogue, we can pin the target environment to:

```text
Java:        21
Spring Boot: 3.5.11
Build:       Maven
Parent:      org.springframework.boot:spring-boot-starter-parent:3.5.11
```

I'd make "do not silently upgrade framework versions" an agent rule. The 3.5 line has subsequently moved beyond 3.5.11, so our skill should treat **3.5.11 as an intentional project constraint**, not "latest Spring Boot". Spring's current documentation lists newer 3.5.x releases. ([Home][1])

---

# 1. Relationship with `java-standards`

### MUST

* Apply `java-standards` first.
* Treat this skill as additive rather than replacement guidance.
* Prefer normal Java constructs when Spring adds no useful capability.
* Follow Spring Boot conventions where they simplify framework integration.
* Respect the project's pinned Java and Spring Boot versions.

### SHOULD

* Keep framework concerns toward application/infrastructure boundaries.
* Keep domain/business logic as ordinary Java wherever practical.
* Minimize unnecessary Spring coupling.
* Let Spring manage objects that genuinely participate in application infrastructure/lifecycle.

### AVOID

* Repeating vanilla Java rules here.
* Turning every Java class into a Spring bean.
* Adding Spring annotations merely because Spring is available.

### NEVER

* Override a base Java rule solely because "this is Spring".

I think that principle should literally appear near the top of `SKILL.md`.

---

# 2. Spring Boot conventions over manual Spring configuration

### SHOULD

* Prefer Spring Boot auto-configuration.
* Prefer starters over assembling individual Spring dependencies manually.
* Use conventional Boot mechanisms before writing custom infrastructure.
* Allow Boot to manage dependency versions covered by its dependency management.

Spring Boot's dependency management exists specifically so managed dependencies can normally be declared without individual versions. ([Home][2])

### CONSIDER

* Custom configuration when Boot's defaults genuinely don't satisfy the application requirement.

### AVOID

* Recreating Boot auto-configuration manually.
* Explicitly configuring infrastructure already correctly configured by Boot.
* Overriding managed dependency versions casually.

### NEVER

* Introduce dependency-version overrides merely to get a newer version without understanding compatibility with Boot 3.5.11.

This is an important AI-agent guardrail.

---

# 3. Application entry point

### SHOULD

Use the conventional entry point:

```java
@SpringBootApplication
public class Application {

    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
}
```

Place it in an appropriate root package above the application packages.

Spring specifically recommends locating the primary application class in a root package because its location establishes useful component/entity scanning boundaries. ([Home][3])

### AVOID

* Multiple unrelated `@SpringBootApplication` classes.
* Putting the application class in an arbitrary leaf package.
* Explicit component scanning when normal package structure solves it.

### NEVER

* Use Java's default package.

Spring explicitly warns against the default package because scanning annotations can then cause every class from every jar to be considered. ([Home][3])

---

# 4. Dependency injection

This is probably one of our strongest Spring standards.

### MUST

* Make required dependencies explicit.

### SHOULD

* Prefer **constructor injection**.
* Make injected dependencies `final`.
* Omit `@Autowired` when a bean has a single constructor.
* Keep constructor dependencies meaningful and reasonably cohesive.

For example:

```java
@Service
public class PaymentService {

    private final PaymentRepository repository;
    private final PaymentGateway gateway;

    public PaymentService(
            PaymentRepository repository,
            PaymentGateway gateway) {
        this.repository = repository;
        this.gateway = gateway;
    }
}
```

Spring supports constructor autowiring and constructor resolution directly. ([Home][4])

### CONSIDER

* Setter injection for genuinely optional/reconfigurable dependencies.

### AVOID

```java
@Autowired
private PaymentRepository repository;
```

That conflicts with our base Java emphasis on explicit dependencies and immutable state.

### NEVER

* Use field injection in new application code without a specific framework/integration reason.
* Fetch ordinary dependencies manually from `ApplicationContext`.

This is a good example of the two skills reinforcing one another rather than conflicting.

---

# 5. Spring stereotypes

### SHOULD

Use the annotation conveying the component's role:

```java
@Component
@Service
@Repository
@Controller
@RestController
```

### AVOID

* Annotating every class with `@Component`.
* Using `@Service` for objects that contain no application/service responsibility.
* Putting Spring annotations on simple value objects, DTOs, records or domain entities without need.

### NEVER

* Turn domain models into Spring beans simply for convenient access.

---

# 6. Component scanning

### SHOULD

* Rely on package structure and `@SpringBootApplication` scanning.
* Keep application packages beneath the application's root package.

Spring Boot explicitly recommends this organization. ([Home][3])

### CONSIDER

Explicit `@ComponentScan` only where package boundaries require it.

### AVOID

* Broad scanning such as arbitrary top-level packages.
* Multiple overlapping scans.
* Scanning third-party packages unnecessarily.

This keeps startup behavior predictable and reduces framework magic.

---

# 7. Configuration classes

### SHOULD

Use explicit configuration classes where bean construction genuinely needs configuration:

```java
@Configuration
public class ClientConfiguration {

    @Bean
    ExternalClient externalClient(ClientProperties properties) {
        return new ExternalClient(properties.baseUrl());
    }
}
```

### SHOULD

* Keep configuration classes focused.
* Use `@Bean` for third-party objects you cannot annotate.
* Prefer explicit bean construction where lifecycle/configuration matters.

### AVOID

* Giant `ApplicationConfiguration` classes containing dozens of unrelated beans.
* `@Bean` wrappers around objects Spring can already configure conventionally.
* Putting business logic into `@Configuration` classes.

---

# 8. `@ConfigurationProperties`

This should be a major rule.

### SHOULD

Prefer strongly typed configuration:

```java
@ConfigurationProperties("payment.gateway")
public record PaymentGatewayProperties(
        URI baseUrl,
        Duration timeout) {
}
```

over scattered:

```java
@Value("${payment.gateway.base-url}")
private String baseUrl;
```

Spring Boot specifically recommends grouping custom configuration in `@ConfigurationProperties`; it provides structured type-safe binding and capabilities not available from `@Value`, including relaxed binding and metadata support. ([Home][5])

### SHOULD

* Use meaningful types:

  * `Duration`
  * `DataSize`
  * `URI`
  * enums
  * collections
  * domain-appropriate values
* Group related properties.
* Validate configuration where invalid values should prevent startup.
* Use canonical kebab-case property names.

### CONSIDER

`@Value` for a genuinely isolated/simple value.

### AVOID

Dozens of scattered:

```java
@Value("${...}")
```

### NEVER

* Read configuration manually from environment variables throughout business code.
* Encode application configuration as arbitrary static constants.

This dovetails beautifully with our Java skill's "typed values over stringly typed APIs" principle.

---

# 9. Configuration validation

### SHOULD

Fail at startup if required configuration is invalid.

For example:

```java
@ConfigurationProperties("remote-service")
@Validated
public record RemoteServiceProperties(
        @NotNull URI baseUrl,
        @Positive Duration timeout) {
}
```

Spring Boot supports validation of configuration-property objects and cascading validation of nested configuration. ([Home][5])

### AVOID

Discovering something such as a missing service URL only when the first request reaches production.

---

# 10. Profiles

### SHOULD

* Use profiles for genuine environment/runtime differences.
* Keep common configuration in the base configuration.
* Keep profile differences minimal.

Spring Boot supports profile-specific configuration overlays and defines deterministic precedence rules. ([Home][5])

### CONSIDER

```yaml
spring:
  config:
    activate:
      on-profile: local
```

### AVOID

* Huge blocks of business logic dependent on active profiles.
* Profiles representing business behavior:

```java
@Profile("premium-customer")
```

* Large numbers of combinatorial profiles.

### NEVER

Use profiles as a feature-flag system by default.

---

# 11. Secrets and external configuration

### MUST

* Keep credentials and secrets out of source code.
* Keep secrets out of committed `application.yml`.

### SHOULD

* Externalize environment-dependent configuration.
* Obtain secrets through the deployment/environment's secret-management mechanism.

Spring Boot's configuration model deliberately supports configuration from external sources with defined precedence. ([Home][5])

### AVOID

```yaml
database:
  password: SuperSecret123
```

in repository configuration.

---

# 12. Business/domain code

This is one I would strongly emphasize.

### SHOULD

Prefer:

```java
public final class PriceCalculator {
    ...
}
```

when the class doesn't need Spring.

Instead of automatically doing:

```java
@Component
public class PriceCalculator {
    ...
}
```

### SHOULD

* Keep pure domain calculations as pure Java.
* Pass dependencies explicitly.
* Keep Spring-specific infrastructure at appropriate boundaries.

### CONSIDER

Making an application service a Spring-managed bean because Spring manages its dependencies/lifecycle.

### AVOID

* `ApplicationContext` in domain code.
* Spring annotations on value objects.
* Framework APIs embedded throughout domain logic.

This directly preserves our vanilla Java skill.

---

# 13. Controllers

Assuming Spring MVC/web is present:

### MUST

* Treat request input as untrusted.
* Validate external input.
* Return appropriate HTTP semantics.

### SHOULD

Controllers should primarily:

1. accept HTTP input;
2. validate/map it;
3. invoke application behavior;
4. translate the result into HTTP output.

For example:

```java
@RestController
@RequestMapping("/customers")
class CustomerController {

    private final CustomerService customerService;

    CustomerController(CustomerService customerService) {
        this.customerService = customerService;
    }

    @PostMapping
    ResponseEntity<CustomerResponse> create(
            @Valid @RequestBody CreateCustomerRequest request) {

        var customer = customerService.create(request);

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(CustomerResponse.from(customer));
    }
}
```

### AVOID

Controllers containing:

* database queries;
* substantial business logic;
* transaction orchestration;
* complex calculations;
* infrastructure logic.

### NEVER

Treat the controller as the application's service layer.

---

# 14. Request/response DTOs

### SHOULD

* Keep transport models distinct where the HTTP contract differs from the domain.
* Consider records for immutable request/response DTOs.
* Validate request DTOs at the boundary.

Example:

```java
public record CreateCustomerRequest(
        @NotBlank String name,
        @Email String email) {
}
```

### AVOID

* Exposing persistence entities directly as API contracts.
* Reusing one "universal DTO" for unrelated API operations.
* DTO-to-DTO abstraction layers that add no value.

The base Java record guidance works naturally here.

---

# 15. Bean Validation

### SHOULD

Use Jakarta Bean Validation for declarative boundary validation where appropriate.

```java
public record CreateOrderRequest(
        @NotNull UUID customerId,
        @Positive int quantity) {
}
```

### SHOULD

* Validate external request/configuration boundaries.
* Keep domain invariants enforced by the domain as well where necessary.

### AVOID

* Treating Bean Validation annotations as a substitute for domain invariants.
* Revalidating everything at every layer.

This directly follows our base Java "validation at boundaries + preserve invariants" principle.

---

# 16. Exception handling

Base Java exception rules remain completely intact.

Spring adds:

### SHOULD

* Translate application exceptions to external HTTP responses at a centralized boundary.
* Use `@RestControllerAdvice` / `@ExceptionHandler` where appropriate.

For example:

```java
@RestControllerAdvice
class ApiExceptionHandler {

    @ExceptionHandler(CustomerNotFoundException.class)
    ResponseEntity<ProblemDetail> handle(
            CustomerNotFoundException exception) {
        ...
    }
}
```

### AVOID

Every controller containing identical:

```java
try {
   ...
} catch (...) {
   ...
}
```

### NEVER

* Return stack traces/internal exception details to clients.
* Swallow exceptions because a controller needs to return HTTP 500.

The Java skill decides **how exceptions should behave**; Spring decides **where HTTP translation belongs**.

---

# 17. `ProblemDetail`

For modern Spring MVC applications:

### SHOULD

Consider Spring's RFC-style `ProblemDetail` support for consistent API error representations rather than inventing ad hoc error structures.

### AVOID

Different error JSON formats for every controller.

This could live in a separate Spring REST reference if we later want to keep the core skill smaller.

---

# 18. Transaction boundaries

If Spring transaction support is present:

### SHOULD

* Place transaction boundaries around coherent application operations.
* Usually place `@Transactional` at service/application boundaries rather than controllers.
* Keep transactions as short as practical.

### AVOID

* `@Transactional` everywhere.
* Transactions around remote HTTP calls unless transaction semantics have explicitly been designed.
* Long-running transactions.
* Controller-level transaction boundaries by default.

### NEVER

Assume `@Transactional` magically makes distributed operations atomic.

This is framework behavior rather than JPA-specific guidance, so I'd keep the basic transaction rule here and put persistence details in another skill.

---

# 19. Self-invocation / proxy awareness

This is an important Spring-specific trap for agents.

### MUST

Understand that some Spring features are applied via proxies.

### AVOID

Designs dependent upon:

```java
this.someTransactionalMethod();
```

triggering proxy-based behavior such as a normal external bean invocation would.

### SHOULD

* Keep proxied concerns at meaningful bean boundaries.
* Prefer straightforward service decomposition over clever proxy workarounds.

This deserves explicit mention because generated Spring code commonly gets it wrong.

---

# 20. Bean scope and state

### MUST

Remember that ordinary Spring beans are singleton-scoped by default.

### SHOULD

* Keep singleton beans stateless where practical.
* Ensure mutable state is thread-safe if it exists in singleton beans.

### AVOID

```java
@Service
class OrderService {
    private Order currentOrder;
}
```

unless this is intentionally synchronized shared application state—which is extraordinarily unusual.

This strongly reinforces our Java concurrency rules.

---

# 21. Lifecycle

### SHOULD

* Let Spring manage resources whose lifecycle belongs to the application context.
* Use supported lifecycle callbacks when genuinely required.
* Make startup failures explicit.

### CONSIDER

* `@PostConstruct`
* `@PreDestroy`
* lifecycle interfaces/events

when appropriate.

### AVOID

* Complex business initialization in constructors.
* Starting unmanaged background threads.
* Shutdown hooks scattered throughout application code.

### NEVER

```java
new Thread(...).start();
```

inside arbitrary Spring bean construction as application infrastructure.

---

# 22. Async execution

### SHOULD

Treat asynchronous execution as an architectural choice.

### CONSIDER

`@Async` when Spring-managed asynchronous execution genuinely matches the requirement.

### AVOID

* Sprinkling `@Async` around slow methods.
* Assuming `@Async` makes work faster.
* Hidden async boundaries.

### NEVER

Use async execution simply to hide latency problems.

Java 21 virtual-thread guidance from `java-standards` still applies. **Spring does not cancel it out.**

---

# 23. Virtual threads

This is a particularly interesting intersection between the two skills.

The Spring skill should say:

> Follow `java-standards` for virtual-thread semantics. Spring Boot configuration may enable/support them, but does not change when virtual threads are conceptually appropriate.

### SHOULD

* Use virtual-thread support for appropriate blocking I/O concurrency if the application's execution model benefits.
* Retain normal resource limits for database connections, downstream concurrency, etc.

### AVOID

* Reactive programming solely because platform threads were historically expensive.
* Assuming enabling virtual threads removes downstream capacity constraints.

Again: this should **reference**, not duplicate, the Java concurrency guidance.

---

# 24. Scheduling

If Spring scheduling is being used:

### SHOULD

* Keep scheduled entry points thin.
* Delegate actual behavior to services.
* Make schedules configurable where deployment needs vary.
* Design scheduled work to tolerate duplicate/overlapping execution where relevant.

### AVOID

```java
@Scheduled(...)
public void doEverything() {
    // 300 lines
}
```

### NEVER

Assume multiple application instances magically coordinate scheduled work.

Distributed scheduling/locking belongs in a separate architectural skill.

---

# 25. Repository/data layer

The core Spring skill should remain light here.

### SHOULD

* Keep persistence behind clear application/domain boundaries.
* Allow Spring's repository abstractions where the chosen persistence technology supports them.

### AVOID

* Database-specific implementation leaking through every layer.
* Calling repositories directly from controllers.

But things such as:

* JPA entity design;
* fetch strategies;
* Hibernate;
* N+1;
* optimistic locking;
* JDBC;
* Spring Data query methods;

should go into something like:

```text
java-spring-data-standards
```

not this core skill.

---

# 26. HTTP clients

Similarly, core rules only.

### SHOULD

* Centralize configuration of outbound HTTP clients.
* Configure explicit timeouts.
* Treat downstream failure as expected distributed-system behavior.
* Use typed request/response models.

### AVOID

* Constructing HTTP clients per request.
* Hard-coded endpoint URLs.
* HTTP calls buried inside domain objects.

Detailed `RestClient`, `WebClient`, retry, resilience etc. could become another reference/skill.

---

# 27. Logging

The Java rule remains:

> don't mandate a logging implementation.

Spring adds:

### SHOULD

* Use the application's configured logging abstraction.
* Include useful operational context.
* Use appropriate levels.

### AVOID

* `System.out`.
* Logging the same exception at every layer.
* Huge request/response payload logging.
* framework debug logging enabled casually in production.

### NEVER

Log credentials or secrets.

---

# 28. Actuator and observability

### SHOULD

For production applications, consider Spring Boot Actuator for standardized health, metrics, diagnostics and operational integration.

### MUST

Treat exposed management endpoints as an operational/security surface.

### AVOID

* Exposing every actuator endpoint publicly.
* Writing custom health mechanisms where standard indicators already solve the need.
* Mixing operational health logic into controllers.

This is firmly Spring Boot-specific.

---

# 29. Health indicators

### SHOULD

* Distinguish application liveness from dependency readiness where deployment infrastructure uses those semantics.
* Keep health checks cheap.

### AVOID

* Expensive database/business operations on every health request.
* Making liveness dependent on every downstream dependency.
* Health indicators with side effects.

---

# 30. Dependency management

Given your chosen parent:

```xml
<parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>3.5.11</version>
</parent>
```

### MUST

Treat that version as authoritative for the project unless specifically instructed otherwise.

### SHOULD

Allow Boot to manage versions for its managed dependency set.

### AVOID

```xml
<dependency>
    ...
    <version>...</version>
</dependency>
```

when Boot already manages that dependency and there's no deliberate override.

Boot maintains a dependency-management catalogue for this purpose. ([Home][1])

### NEVER

Have an agent silently "upgrade dependencies to latest."

This belongs very high in an AI-oriented skill.

---

# 31. Starter selection

### SHOULD

Use the narrowest appropriate starter.

Examples:

```text
spring-boot-starter-web
spring-boot-starter-validation
spring-boot-starter-actuator
spring-boot-starter-data-jpa
```

### AVOID

* Adding starters "just in case."
* Adding both competing stacks unintentionally.
* Pulling in a large starter for one tiny unrelated utility.

---

# 32. Testing strategy

The Spring skill should complement, rather than replace, a later `java-testing-standards`.

Spring Boot has dedicated test support and supports both complete application-context tests and narrower focused test configurations. ([Home][6])

### SHOULD

Use the **smallest test scope that proves the behavior**.

Conceptually:

```text
plain unit test
       ↓
focused Spring test
       ↓
integration test
       ↓
@SpringBootTest
```

### SHOULD

* Test pure Java logic without Spring.
* Load Spring only when the behavior depends on Spring.
* Use focused test slices when testing framework-specific slices.
* Use full application context tests for genuine cross-component behavior.

### AVOID

Putting:

```java
@SpringBootTest
```

on every test.

### NEVER

Start an application context merely because the class under test has a Spring annotation.

This is another huge AI-agent guardrail.

---

# 33. Testcontainers

### CONSIDER

Use Testcontainers for integration tests where behavior genuinely depends on a real external system.

Spring Boot explicitly integrates with Testcontainers and describes it as useful for integration tests involving real backend services. ([Home][7])

### AVOID

* Mocking behavior where the correctness depends strongly on the actual database/broker implementation.
* Conversely, spinning up containers for simple pure unit tests.

Again:

> cheapest correct test first.

---

# 34. Mocking Spring

### SHOULD

* Mock collaborators at genuine boundaries.
* Prefer testing behavior over framework implementation.

### AVOID

Mocking:

* `ApplicationContext`;
* basic domain objects;
* every internal method;
* Spring itself.

### NEVER

Design production classes primarily to make mocking easier.

That remains consistent with our base Java standard.

---

# 35. Package organization

Spring Boot itself does not require a specific layout, although it documents package organization recommendations and shows feature-oriented examples. ([Home][3])

### SHOULD

* Put the application class above application packages.
* Keep related functionality cohesive.
* Respect existing repository organization.

### CONSIDER

Package-by-feature/domain:

```text
com.example.orders
├── OrderController
├── OrderService
├── OrderRepository
└── Order
```

rather than automatically:

```text
controller/
service/
repository/
model/
```

### NEVER

Mandate one package architecture as a universal Spring rule.

That distinction matters.

---

# 36. Annotation restraint

This should probably be its own major section.

### SHOULD

Use annotations when they activate meaningful Spring/framework behavior.

### AVOID

Annotation soup:

```java
@Component
@Transactional
@Validated
@Async
@Retryable
@Cacheable
...
```

without a clearly understood interaction model.

### NEVER

Add an annotation just because it appears common in other Spring projects.

The agent must understand **what behavior an annotation introduces**.

---

# 37. Framework magic versus explicit Java

### SHOULD

Prefer Spring convention where it eliminates infrastructure boilerplate.

Prefer ordinary Java where it expresses business behavior more clearly.

That gives us a useful dividing line:

```text
Framework concern        → Spring idiom
Business/domain concern  → Java idiom
```

For example:

```text
Dependency wiring        → Spring
Configuration binding    → Spring
HTTP routing             → Spring
Lifecycle                → Spring

Calculation              → Java
Domain invariants        → Java
Value objects            → Java
Algorithms               → Java
```

This might be the **single most important architectural principle** of the combined skills.

---

# 38. Framework escape hatches

### CONSIDER

Low-level Spring APIs only when higher-level Boot conventions cannot express the requirement.

Examples include:

* `BeanFactory`
* `ApplicationContext`
* `Environment`
* programmatic bean registration;
* manual lifecycle manipulation.

### AVOID

Injecting:

```java
ApplicationContext
Environment
BeanFactory
```

into ordinary business services.

Spring Boot's own configuration guidance, for example, recommends keeping `@ConfigurationProperties` focused on environment binding rather than injecting other application beans into those objects. ([Home][5])

---

# 39. Spring-specific AI anti-patterns

I'd give these a prominent section.

### AVOID

An agent automatically creating:

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

for every feature.

Instead:

> Create only the components justified by the requirement.

Likewise avoid automatically adding:

* `@Transactional`;
* `@Async`;
* `@Cacheable`;
* `@Retryable`;
* interfaces;
* DTOs;
* mappers;
* configuration classes;
* profiles;
* event publishers.

Each must solve an actual problem.

---

# 40. Agent change discipline

### MUST

* Preserve the existing Spring Boot version.
* Preserve Java 21.
* Respect existing Spring conventions in the repository.
* Understand an annotation before introducing it.
* Maintain bean wiring correctness.
* Maintain configuration compatibility.
* Keep tests/build working.

### SHOULD

* Prefer Boot conventions over custom framework plumbing.
* Make the smallest Spring-aware change.
* Reuse existing configuration/components where appropriate.
* Match existing dependency-management practices.
* Use existing application architecture rather than inventing another one.

### AVOID

* Opportunistic Spring upgrades.
* Dependency version overrides.
* Broad component scans.
* unrelated configuration changes.
* turning non-Spring Java into Spring-managed code without reason.
* loading the entire application context in every test.
* adding framework features speculatively.

### NEVER

* Upgrade Spring Boot or managed dependencies silently.
* Introduce a Spring abstraction merely because it exists.
* Hide broken design behind annotations.

---

# What should deliberately **not** live in this skill

I think this boundary is as important as what goes into it.

| Concern                            | Better home                           |
| ---------------------------------- | ------------------------------------- |
| Core Java                          | `java-standards`                      |
| JUnit/Mockito detailed conventions | `java-testing-standards`              |
| JPA/Hibernate                      | `java-spring-data-jpa-standards`      |
| JDBC                               | `java-spring-jdbc-standards`          |
| Kafka                              | `java-spring-kafka-standards`         |
| REST API design                    | Possibly `java-spring-rest-standards` |
| Spring Security                    | `java-spring-security-standards`      |
| Resilience4j                       | `java-resilience-standards`           |
| OpenAPI                            | separate API skill                    |
| AWS                                | infrastructure-specific skill         |
| Kubernetes                         | deployment skill                      |
| Maven                              | `java-maven-standards`                |
| architectural style                | architecture skill                    |
| DDD                                | domain-design skill                   |

This prevents us eventually ending up with a 2,000-line "Spring skill that knows everything."

---

# The relationship becomes quite elegant

I'd conceptualize it like this:

```text
                     java-standards
                           │
              ┌────────────┴────────────┐
              │                         │
   java-testing-standards       java-springboot-standards
                                        │
                     ┌──────────────────┼─────────────────┐
                     │                  │                 │
              spring-data         spring-rest       spring-kafka
                standards          standards          standards
                     │
                JPA / JDBC
```

And an implementation request might activate:

```text
"Add an endpoint that stores a customer"
             │
             ├── java-standards
             │
             ├── java-springboot-standards
             │
             ├── java-spring-rest-standards
             │
             └── java-spring-data-jpa-standards
```

rather than one gigantic Java/Spring skill.

## The core Spring rules I'd put in immediate agent context

Like we did with Java, the full catalogue is too large to load constantly. I'd boil `SKILL.md` itself down to something close to these:

1. **Apply `java-standards` first.**
2. **Target Java 21 and Spring Boot 3.5.11; never upgrade either implicitly.**
3. **Prefer Spring Boot conventions and auto-configuration over custom framework plumbing.**
4. **Use constructor injection for required dependencies; avoid field injection.**
5. **Keep business/domain logic ordinary Java where practical.**
6. **Make only objects requiring framework management Spring beans.**
7. **Prefer typed `@ConfigurationProperties` for related application configuration.**
8. **Keep controllers thin and delegate application behavior.**
9. **Validate external input at boundaries and preserve domain invariants internally.**
10. **Keep transaction boundaries around coherent application operations, not controllers.**
11. **Remember singleton Spring beans must not contain unsafe request-specific mutable state.**
12. **Load only as much Spring context as a test actually requires.**
13. **Let Spring Boot manage dependency versions wherever possible.**
14. **Use annotations only when their behavior is understood and required.**
15. **Do not create layers, interfaces, DTOs, mappers or configuration classes speculatively.**
16. **Do not refactor unrelated Java into Spring-style code.**
17. **Make the smallest coherent framework-aware change.**

And then I would probably structure the actual skill as:

```text
java-springboot-standards/
├── SKILL.md
└── references/
    ├── dependency-injection.md
    ├── beans-and-configuration.md
    ├── configuration-properties.md
    ├── web-and-validation.md
    ├── transactions-and-lifecycle.md
    ├── concurrency-and-scheduling.md
    ├── testing.md
    ├── operations-and-observability.md
    └── anti-patterns.md
```

The important architectural insight here is that **the vanilla Java skill should own code quality; the Spring Boot skill should own correct use of the framework**. That boundary keeps them composable instead of having two agents' worth of instructions fighting over how the same Java code ought to look.

[1]: https://docs.spring.io/spring-boot/appendix/dependency-versions/index.html?utm_source=chatgpt.com "Dependency Versions :: Spring Boot"
[2]: https://docs.spring.io/spring-boot/docs/3.0.x/reference/html/dependency-versions.html?utm_source=chatgpt.com "Dependency Versions"
[3]: https://docs.spring.io/spring-boot/reference/using/structuring-your-code.html?utm_source=chatgpt.com "Structuring Your Code :: Spring Boot"
[4]: https://docs.spring.io/spring-framework/reference/core/beans/annotation-config/autowired.html?utm_source=chatgpt.com "Using @Autowired"
[5]: https://docs.spring.io/spring-boot/reference/features/external-config.html?utm_source=chatgpt.com "Externalized Configuration :: Spring Boot"
[6]: https://docs.spring.io/spring-boot/reference/testing/index.html?utm_source=chatgpt.com "Testing :: Spring Boot"
[7]: https://docs.spring.io/spring-boot/reference/testing/testcontainers.html?utm_source=chatgpt.com "Testcontainers :: Spring Boot"
