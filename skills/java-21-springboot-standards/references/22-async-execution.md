## 22. Async execution

### SHOULD

Treat asynchronous execution as an architectural choice.

### CONSIDER

`@Async` when Spring-managed asynchronous execution genuinely matches the requirement.

To enable Spring async support, `@EnableAsync` must be present on a configuration class (usually `@SpringBootApplication`).

### `@Async` return type contract

A method annotated with `@Async` must return one of:

* `void` — fire-and-forget; exceptions are silently swallowed unless an `AsyncUncaughtExceptionHandler` is configured
* `Future<T>` / `CompletableFuture<T>` — caller can observe the result or handle exceptions

```java
// Exceptions silently lost without AsyncUncaughtExceptionHandler
@Async
public void notifyDownstream(Event event) { ... }

// Caller can handle completion or failure
@Async
public CompletableFuture<Result> processAsync(Command cmd) { ... }
```

### Self-invocation trap

`@Async` is proxy-backed. Calling `this.asyncMethod()` from within the same bean bypasses the proxy and executes **synchronously**. See [section 19](./19-self-invocation-proxy-awareness.md).

### Thread pool

`@Async` uses `SimpleAsyncTaskExecutor` by default, which creates a new thread per invocation. For production code, configure a named `Executor` bean:

```java
@Bean(name = "taskExecutor")
public Executor taskExecutor() {
    var executor = new ThreadPoolTaskExecutor();
    executor.setCorePoolSize(2);
    executor.setMaxPoolSize(10);
    executor.setQueueCapacity(100);
    return executor;
}
```

### AVOID

* Sprinkling `@Async` around slow methods.
* Assuming `@Async` makes work faster.
* Hidden async boundaries.
* Using a `void` return type when the caller needs to know about failures.

### NEVER

Use async execution simply to hide latency problems.

Java 21 virtual-thread guidance from `java-21-standards` still applies. **Spring does not cancel it out.**
