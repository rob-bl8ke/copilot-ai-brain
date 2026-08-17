## 10. Profiles

### SHOULD

* Use profiles for genuine environment/runtime differences.
* Keep common configuration in the base configuration.
* Keep profile differences minimal.

Spring Boot supports profile-specific configuration overlays and defines deterministic precedence rules. ([Spring docs][5])

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

[1]: https://docs.spring.io/spring-boot/appendix/dependency-versions/index.html "Dependency Versions :: Spring Boot"
[2]: https://docs.spring.io/spring-boot/docs/3.0.x/reference/html/dependency-versions.html "Dependency Versions"
[3]: https://docs.spring.io/spring-boot/reference/using/structuring-your-code.html "Structuring Your Code :: Spring Boot"
[4]: https://docs.spring.io/spring-framework/reference/core/beans/annotation-config/autowired.html "Using @Autowired"
[5]: https://docs.spring.io/spring-boot/reference/features/external-config.html "Externalized Configuration :: Spring Boot"
[6]: https://docs.spring.io/spring-boot/reference/testing/index.html "Testing :: Spring Boot"
[7]: https://docs.spring.io/spring-boot/reference/testing/testcontainers.html "Testcontainers :: Spring Boot"
