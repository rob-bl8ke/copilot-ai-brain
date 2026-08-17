## 7. Configuration classes

### SHOULD

Use explicit configuration classes where bean construction genuinely needs configuration:

```java
@Configuration
public class ClientConfiguration {

    @Bean
    ExternalClient externalClient(ClientProperties properties) {
        return new ExternalClient(properties.baseUrl());
    }
}
```

### SHOULD

* Keep configuration classes focused.
* Use `@Bean` for third-party objects you cannot annotate.
* Prefer explicit bean construction where lifecycle/configuration matters.

### AVOID

* Giant `ApplicationConfiguration` classes containing dozens of unrelated beans.
* `@Bean` wrappers around objects Spring can already configure conventionally.
* Putting business logic into `@Configuration` classes.
