## 21. Lifecycle

### SHOULD

* Let Spring manage resources whose lifecycle belongs to the application context.
* Use supported lifecycle callbacks when genuinely required.
* Make startup failures explicit.

### CONSIDER

* `@PostConstruct`
* `@PreDestroy`
* lifecycle interfaces/events

when appropriate.

### AVOID

* Complex business initialization in constructors.
* Starting unmanaged background threads.
* Shutdown hooks scattered throughout application code.

### NEVER

```java
new Thread(...).start();
```

inside arbitrary Spring bean construction as application infrastructure.
