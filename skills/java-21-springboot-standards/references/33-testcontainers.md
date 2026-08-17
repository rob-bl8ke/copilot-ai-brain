## 33. Testcontainers

> **Skill deferral:** When `java-21-springboot-integration-tests` is present, defer to it for `@DataJpaTest` + Testcontainers setup. When `java-21-springboot-e2e-tests` is present, defer to it for full-stack `@SpringBootTest` container wiring. This file is fallback guidance for projects where those skills are not available.

### CONSIDER

Use Testcontainers for integration tests where behaviour genuinely depends on a real external system.

Spring Boot explicitly integrates with Testcontainers and describes it as useful for integration tests involving real backend services. ([Spring docs][7])

### AVOID

* Mocking behaviour where correctness depends strongly on the actual database or broker implementation.
* Conversely, spinning up containers for simple pure unit tests.

> Cheapest correct test first.

[1]: https://docs.spring.io/spring-boot/appendix/dependency-versions/index.html "Dependency Versions :: Spring Boot"
[2]: https://docs.spring.io/spring-boot/docs/3.0.x/reference/html/dependency-versions.html "Dependency Versions"
[3]: https://docs.spring.io/spring-boot/reference/using/structuring-your-code.html "Structuring Your Code :: Spring Boot"
[4]: https://docs.spring.io/spring-framework/reference/core/beans/annotation-config/autowired.html "Using @Autowired"
[5]: https://docs.spring.io/spring-boot/reference/features/external-config.html "Externalized Configuration :: Spring Boot"
[6]: https://docs.spring.io/spring-boot/reference/testing/index.html "Testing :: Spring Boot"
[7]: https://docs.spring.io/spring-boot/reference/testing/testcontainers.html "Testcontainers :: Spring Boot"
