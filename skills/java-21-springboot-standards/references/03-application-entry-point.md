## 3. Application entry point

### SHOULD

Use the conventional entry point:

```java
@SpringBootApplication
public class Application {

    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
}
```

Place it in an appropriate root package above the application packages.

Spring specifically recommends locating the primary application class in a root package because its location establishes useful component/entity scanning boundaries. ([Spring docs][3])

### AVOID

* Multiple unrelated `@SpringBootApplication` classes.
* Putting the application class in an arbitrary leaf package.
* Explicit component scanning when normal package structure solves it.

### NEVER

* Use Java's default package.

Spring explicitly warns against the default package because scanning annotations can then cause every class from every jar to be considered. ([Spring docs][3])

[1]: https://docs.spring.io/spring-boot/appendix/dependency-versions/index.html "Dependency Versions :: Spring Boot"
[2]: https://docs.spring.io/spring-boot/docs/3.0.x/reference/html/dependency-versions.html "Dependency Versions"
[3]: https://docs.spring.io/spring-boot/reference/using/structuring-your-code.html "Structuring Your Code :: Spring Boot"
[4]: https://docs.spring.io/spring-framework/reference/core/beans/annotation-config/autowired.html "Using @Autowired"
[5]: https://docs.spring.io/spring-boot/reference/features/external-config.html "Externalized Configuration :: Spring Boot"
[6]: https://docs.spring.io/spring-boot/reference/testing/index.html "Testing :: Spring Boot"
[7]: https://docs.spring.io/spring-boot/reference/testing/testcontainers.html "Testcontainers :: Spring Boot"
