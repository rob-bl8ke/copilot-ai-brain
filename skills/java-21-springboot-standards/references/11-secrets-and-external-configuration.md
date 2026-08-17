## 11. Secrets and external configuration

### MUST

* Keep credentials and secrets out of source code.
* Keep secrets out of committed `application.yml`.

### SHOULD

* Externalize environment-dependent configuration.
* Obtain secrets through the deployment/environment's secret-management mechanism.

Spring Boot's configuration model deliberately supports configuration from external sources with defined precedence. ([Spring docs][5])

### AVOID

```yaml
database:
  password: SuperSecret123
```

in repository configuration.

[1]: https://docs.spring.io/spring-boot/appendix/dependency-versions/index.html "Dependency Versions :: Spring Boot"
[2]: https://docs.spring.io/spring-boot/docs/3.0.x/reference/html/dependency-versions.html "Dependency Versions"
[3]: https://docs.spring.io/spring-boot/reference/using/structuring-your-code.html "Structuring Your Code :: Spring Boot"
[4]: https://docs.spring.io/spring-framework/reference/core/beans/annotation-config/autowired.html "Using @Autowired"
[5]: https://docs.spring.io/spring-boot/reference/features/external-config.html "Externalized Configuration :: Spring Boot"
[6]: https://docs.spring.io/spring-boot/reference/testing/index.html "Testing :: Spring Boot"
[7]: https://docs.spring.io/spring-boot/reference/testing/testcontainers.html "Testcontainers :: Spring Boot"
