## 9. Configuration validation

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

Spring Boot supports validation of configuration-property objects and cascading validation of nested configuration. ([Spring docs][5])

### AVOID

Discovering something such as a missing service URL only when the first request reaches production.

[1]: https://docs.spring.io/spring-boot/appendix/dependency-versions/index.html "Dependency Versions :: Spring Boot"
[2]: https://docs.spring.io/spring-boot/docs/3.0.x/reference/html/dependency-versions.html "Dependency Versions"
[3]: https://docs.spring.io/spring-boot/reference/using/structuring-your-code.html "Structuring Your Code :: Spring Boot"
[4]: https://docs.spring.io/spring-framework/reference/core/beans/annotation-config/autowired.html "Using @Autowired"
[5]: https://docs.spring.io/spring-boot/reference/features/external-config.html "Externalized Configuration :: Spring Boot"
[6]: https://docs.spring.io/spring-boot/reference/testing/index.html "Testing :: Spring Boot"
[7]: https://docs.spring.io/spring-boot/reference/testing/testcontainers.html "Testcontainers :: Spring Boot"
