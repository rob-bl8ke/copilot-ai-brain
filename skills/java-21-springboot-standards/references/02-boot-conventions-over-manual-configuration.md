## 2. Spring Boot conventions over manual Spring configuration

### SHOULD

* Prefer Spring Boot auto-configuration.
* Prefer starters over assembling individual Spring dependencies manually.
* Use conventional Boot mechanisms before writing custom infrastructure.
* Allow Boot to manage dependency versions covered by its dependency management.

Spring Boot's dependency management exists specifically so managed dependencies can normally be declared without individual versions. ([Spring docs][2])

### CONSIDER

* Custom configuration when Boot's defaults genuinely don't satisfy the application requirement.

### AVOID

* Recreating Boot auto-configuration manually.
* Explicitly configuring infrastructure already correctly configured by Boot.
* Overriding managed dependency versions casually.

### NEVER

* Introduce dependency-version overrides merely to get a newer version without understanding compatibility with Boot 3.5.11.

This is an important AI-agent guardrail.

[1]: https://docs.spring.io/spring-boot/appendix/dependency-versions/index.html "Dependency Versions :: Spring Boot"
[2]: https://docs.spring.io/spring-boot/docs/3.0.x/reference/html/dependency-versions.html "Dependency Versions"
[3]: https://docs.spring.io/spring-boot/reference/using/structuring-your-code.html "Structuring Your Code :: Spring Boot"
[4]: https://docs.spring.io/spring-framework/reference/core/beans/annotation-config/autowired.html "Using @Autowired"
[5]: https://docs.spring.io/spring-boot/reference/features/external-config.html "Externalized Configuration :: Spring Boot"
[6]: https://docs.spring.io/spring-boot/reference/testing/index.html "Testing :: Spring Boot"
[7]: https://docs.spring.io/spring-boot/reference/testing/testcontainers.html "Testcontainers :: Spring Boot"
