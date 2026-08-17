## 16. Exception handling

Base Java exception rules remain completely intact.

Spring adds:

### SHOULD

* Translate application exceptions to external HTTP responses at a centralized boundary.
* Use `@RestControllerAdvice` / `@ExceptionHandler` where appropriate.

For example:

```java
@RestControllerAdvice
class ApiExceptionHandler {

    @ExceptionHandler(CustomerNotFoundException.class)
    ResponseEntity<ProblemDetail> handle(
            CustomerNotFoundException exception) {
        ...
    }
}
```

### AVOID

Every controller containing identical:

```java
try {
   ...
} catch (...) {
   ...
}
```

### NEVER

* Return stack traces/internal exception details to clients.
* Swallow exceptions because a controller needs to return HTTP 500.

The Java skill decides **how exceptions should behave**; Spring decides **where HTTP translation belongs**.
