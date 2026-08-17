## 30. Dependency management

Given your chosen parent:

```xml
<parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>3.5.11</version>
</parent>
```

### MUST

Treat that version as authoritative for the project unless specifically instructed otherwise.

### SHOULD

Allow Boot to manage versions for its managed dependency set.

### AVOID

```xml
<dependency>
    ...
    <version>...</version>
</dependency>
```

when Boot already manages that dependency and there's no deliberate override.

Boot maintains a dependency-management catalogue for this purpose. ([Spring docs][1])

### NEVER

Have an agent silently "upgrade dependencies to latest."

This belongs very high in an AI-oriented skill.

[1]: https://docs.spring.io/spring-boot/appendix/dependency-versions/index.html "Dependency Versions :: Spring Boot"
[2]: https://docs.spring.io/spring-boot/docs/3.0.x/reference/html/dependency-versions.html "Dependency Versions"
[3]: https://docs.spring.io/spring-boot/reference/using/structuring-your-code.html "Structuring Your Code :: Spring Boot"
[4]: https://docs.spring.io/spring-framework/reference/core/beans/annotation-config/autowired.html "Using @Autowired"
[5]: https://docs.spring.io/spring-boot/reference/features/external-config.html "Externalized Configuration :: Spring Boot"
[6]: https://docs.spring.io/spring-boot/reference/testing/index.html "Testing :: Spring Boot"
[7]: https://docs.spring.io/spring-boot/reference/testing/testcontainers.html "Testcontainers :: Spring Boot"
