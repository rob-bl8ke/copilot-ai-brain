## 35. Package organization

Spring Boot itself does not require a specific layout, although it documents package organization recommendations and shows feature-oriented examples. ([Spring docs][3])

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

[1]: https://docs.spring.io/spring-boot/appendix/dependency-versions/index.html "Dependency Versions :: Spring Boot"
[2]: https://docs.spring.io/spring-boot/docs/3.0.x/reference/html/dependency-versions.html "Dependency Versions"
[3]: https://docs.spring.io/spring-boot/reference/using/structuring-your-code.html "Structuring Your Code :: Spring Boot"
[4]: https://docs.spring.io/spring-framework/reference/core/beans/annotation-config/autowired.html "Using @Autowired"
[5]: https://docs.spring.io/spring-boot/reference/features/external-config.html "Externalized Configuration :: Spring Boot"
[6]: https://docs.spring.io/spring-boot/reference/testing/index.html "Testing :: Spring Boot"
[7]: https://docs.spring.io/spring-boot/reference/testing/testcontainers.html "Testcontainers :: Spring Boot"
