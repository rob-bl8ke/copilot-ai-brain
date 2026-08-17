## 6. Component scanning

### SHOULD

* Rely on package structure and `@SpringBootApplication` scanning.
* Keep application packages beneath the application's root package.

Spring Boot explicitly recommends this organization. ([Spring docs][3])

### CONSIDER

Explicit `@ComponentScan` only where package boundaries require it.

### AVOID

* Broad scanning such as arbitrary top-level packages.
* Multiple overlapping scans.
* Scanning third-party packages unnecessarily.

This keeps startup behavior predictable and reduces framework magic.

[1]: https://docs.spring.io/spring-boot/appendix/dependency-versions/index.html "Dependency Versions :: Spring Boot"
[2]: https://docs.spring.io/spring-boot/docs/3.0.x/reference/html/dependency-versions.html "Dependency Versions"
[3]: https://docs.spring.io/spring-boot/reference/using/structuring-your-code.html "Structuring Your Code :: Spring Boot"
[4]: https://docs.spring.io/spring-framework/reference/core/beans/annotation-config/autowired.html "Using @Autowired"
[5]: https://docs.spring.io/spring-boot/reference/features/external-config.html "Externalized Configuration :: Spring Boot"
[6]: https://docs.spring.io/spring-boot/reference/testing/index.html "Testing :: Spring Boot"
[7]: https://docs.spring.io/spring-boot/reference/testing/testcontainers.html "Testcontainers :: Spring Boot"
