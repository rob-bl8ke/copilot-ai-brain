## 8. `@ConfigurationProperties`

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

Spring Boot specifically recommends grouping custom configuration in `@ConfigurationProperties`; it provides structured type-safe binding and capabilities not available from `@Value`, including relaxed binding and metadata support. ([Spring docs][5])

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

This supports the Java standard of preferring typed values over stringly typed APIs.

[1]: https://docs.spring.io/spring-boot/appendix/dependency-versions/index.html "Dependency Versions :: Spring Boot"
[2]: https://docs.spring.io/spring-boot/docs/3.0.x/reference/html/dependency-versions.html "Dependency Versions"
[3]: https://docs.spring.io/spring-boot/reference/using/structuring-your-code.html "Structuring Your Code :: Spring Boot"
[4]: https://docs.spring.io/spring-framework/reference/core/beans/annotation-config/autowired.html "Using @Autowired"
[5]: https://docs.spring.io/spring-boot/reference/features/external-config.html "Externalized Configuration :: Spring Boot"
[6]: https://docs.spring.io/spring-boot/reference/testing/index.html "Testing :: Spring Boot"
[7]: https://docs.spring.io/spring-boot/reference/testing/testcontainers.html "Testcontainers :: Spring Boot"
