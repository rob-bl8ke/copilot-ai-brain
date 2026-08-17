## 32. Testing strategy

> **Skill deferral:** When `java-21-springboot-unit-testing`, `java-21-springboot-integration-tests`, or `java-21-springboot-e2e-tests` skills are present, defer to them for their respective test categories — they contain project-specific conventions that take precedence over this general guidance. This file is the fallback for projects where those skills are not available.

Spring Boot has dedicated test support and supports both complete application-context tests and narrower focused test configurations. ([Spring docs][6])

### SHOULD

Use the **smallest test scope that proves the behaviour**.

```text
plain unit test          → no Spring context
       ↓
focused slice test       → minimal context (e.g. @WebMvcTest, @DataJpaTest)
       ↓
integration test         → real infrastructure (Testcontainers)
       ↓
@SpringBootTest          → full context, cross-component
```

### Spring test slice selection

| What you are testing | Annotation | What gets loaded |
|---|---|---|
| Pure business/domain logic | `@Test` (no Spring) | Nothing |
| HTTP layer only | `@WebMvcTest(FooController.class)` | Controllers, filters, `@ControllerAdvice`, Jackson |
| JPA/persistence layer only | `@DataJpaTest` | JPA, datasource, migrations |
| Full cross-component behaviour | `@SpringBootTest` | Full application context |

### Mocking beans in Spring tests (`@MockitoBean`)

For Spring Boot 3.4+ (including 3.5.x), use `@MockitoBean` to replace a bean in the application context. `@MockBean` was deprecated in Spring Boot 3.4.

```java
@WebMvcTest(CustomerController.class)
class CustomerControllerTest {

    @MockitoBean
    private CustomerService customerService;

    // ...
}
```

### SHOULD

* Test pure Java logic without Spring.
* Load Spring only when the behaviour depends on Spring.
* Use focused slices when testing a single framework layer.
* Use `@SpringBootTest` for genuine cross-component behaviour only.

### AVOID

Putting `@SpringBootTest` on every test.

### NEVER

Start an application context merely because the class under test has a Spring annotation.

This is an important AI-agent guardrail.

[1]: https://docs.spring.io/spring-boot/appendix/dependency-versions/index.html "Dependency Versions :: Spring Boot"
[2]: https://docs.spring.io/spring-boot/docs/3.0.x/reference/html/dependency-versions.html "Dependency Versions"
[3]: https://docs.spring.io/spring-boot/reference/using/structuring-your-code.html "Structuring Your Code :: Spring Boot"
[4]: https://docs.spring.io/spring-framework/reference/core/beans/annotation-config/autowired.html "Using @Autowired"
[5]: https://docs.spring.io/spring-boot/reference/features/external-config.html "Externalized Configuration :: Spring Boot"
[6]: https://docs.spring.io/spring-boot/reference/testing/index.html "Testing :: Spring Boot"
[7]: https://docs.spring.io/spring-boot/reference/testing/testcontainers.html "Testcontainers :: Spring Boot"
