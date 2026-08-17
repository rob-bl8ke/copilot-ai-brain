## 4. Dependency injection

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

Spring supports constructor autowiring and constructor resolution directly. ([Spring docs][4])

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

[1]: https://docs.spring.io/spring-boot/appendix/dependency-versions/index.html "Dependency Versions :: Spring Boot"
[2]: https://docs.spring.io/spring-boot/docs/3.0.x/reference/html/dependency-versions.html "Dependency Versions"
[3]: https://docs.spring.io/spring-boot/reference/using/structuring-your-code.html "Structuring Your Code :: Spring Boot"
[4]: https://docs.spring.io/spring-framework/reference/core/beans/annotation-config/autowired.html "Using @Autowired"
[5]: https://docs.spring.io/spring-boot/reference/features/external-config.html "Externalized Configuration :: Spring Boot"
[6]: https://docs.spring.io/spring-boot/reference/testing/index.html "Testing :: Spring Boot"
[7]: https://docs.spring.io/spring-boot/reference/testing/testcontainers.html "Testcontainers :: Spring Boot"
