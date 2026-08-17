## 22. Async execution

### SHOULD

Treat asynchronous execution as an architectural choice.

### CONSIDER

`@Async` when Spring-managed asynchronous execution genuinely matches the requirement.

### AVOID

* Sprinkling `@Async` around slow methods.
* Assuming `@Async` makes work faster.
* Hidden async boundaries.

### NEVER

Use async execution simply to hide latency problems.

Java 21 virtual-thread guidance from `java-21-standards` still applies. **Spring does not cancel it out.**
