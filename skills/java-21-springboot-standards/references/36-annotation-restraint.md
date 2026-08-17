## 36. Annotation restraint

### SHOULD

Use annotations when they activate meaningful Spring/framework behavior.

### AVOID

Annotation soup:

```java
@Component
@Transactional
@Validated
@Async
@Retryable
@Cacheable
...
```

without a clearly understood interaction model.

### NEVER

Add an annotation just because it appears common in other Spring projects.

The agent must understand **what behavior an annotation introduces**.
