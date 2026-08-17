## 32. Testing strategy

The Spring skill should complement, rather than replace, a later `java-testing-standards`.

Spring Boot has dedicated test support and supports both complete application-context tests and narrower focused test configurations. ([Spring docs][6])

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

This is an important AI-agent guardrail.

[1]: https://docs.spring.io/spring-boot/appendix/dependency-versions/index.html "Dependency Versions :: Spring Boot"
[2]: https://docs.spring.io/spring-boot/docs/3.0.x/reference/html/dependency-versions.html "Dependency Versions"
[3]: https://docs.spring.io/spring-boot/reference/using/structuring-your-code.html "Structuring Your Code :: Spring Boot"
[4]: https://docs.spring.io/spring-framework/reference/core/beans/annotation-config/autowired.html "Using @Autowired"
[5]: https://docs.spring.io/spring-boot/reference/features/external-config.html "Externalized Configuration :: Spring Boot"
[6]: https://docs.spring.io/spring-boot/reference/testing/index.html "Testing :: Spring Boot"
[7]: https://docs.spring.io/spring-boot/reference/testing/testcontainers.html "Testcontainers :: Spring Boot"
