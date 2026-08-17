## 34. Mocking Spring

> **Skill deferral:** When the `java-21-springboot-unit-testing` skill is present, defer to it. This file covers Spring-generic mocking rules only.

### `@MockitoBean` for Spring Boot 3.4+

Use `@MockitoBean` to replace a Spring bean in the application context within a slice or full-context test. `@MockBean` was deprecated in Spring Boot 3.4 and replaced by `@MockitoBean`:

```java
// Spring Boot 3.4+ / 3.5.x — correct
@MockitoBean
private PaymentGateway paymentGateway;

// Deprecated since Spring Boot 3.4 — avoid in new code
@MockBean
private PaymentGateway paymentGateway;
```

### SHOULD

* Mock collaborators at genuine boundaries.
* Prefer testing behaviour over framework implementation.

### AVOID

Mocking:

* `ApplicationContext`;
* basic domain objects;
* every internal method;
* Spring itself.

### NEVER

Design production classes primarily to make mocking easier.

That remains consistent with our base Java standard.
