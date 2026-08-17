## 38. Framework escape hatches

### CONSIDER

Low-level Spring APIs only when higher-level Boot conventions cannot express the requirement.

Examples include:

* `BeanFactory`
* `ApplicationContext`
* `Environment`
* programmatic bean registration;
* manual lifecycle manipulation.

### AVOID

Injecting:

```java
ApplicationContext
Environment
BeanFactory
```

into ordinary business services.

Spring Boot's own configuration guidance, for example, recommends keeping `@ConfigurationProperties` focused on environment binding rather than injecting other application beans into those objects. ([Spring docs][5])

[1]: https://docs.spring.io/spring-boot/appendix/dependency-versions/index.html "Dependency Versions :: Spring Boot"
[2]: https://docs.spring.io/spring-boot/docs/3.0.x/reference/html/dependency-versions.html "Dependency Versions"
[3]: https://docs.spring.io/spring-boot/reference/using/structuring-your-code.html "Structuring Your Code :: Spring Boot"
[4]: https://docs.spring.io/spring-framework/reference/core/beans/annotation-config/autowired.html "Using @Autowired"
[5]: https://docs.spring.io/spring-boot/reference/features/external-config.html "Externalized Configuration :: Spring Boot"
[6]: https://docs.spring.io/spring-boot/reference/testing/index.html "Testing :: Spring Boot"
[7]: https://docs.spring.io/spring-boot/reference/testing/testcontainers.html "Testcontainers :: Spring Boot"
