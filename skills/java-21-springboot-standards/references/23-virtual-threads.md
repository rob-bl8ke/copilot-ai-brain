## 23. Virtual threads

> Follow `java-21-standards` for virtual-thread semantics. Spring Boot configuration may enable/support them, but does not change when virtual threads are conceptually appropriate.

### SHOULD

* Use virtual-thread support for appropriate blocking I/O concurrency if the application's execution model benefits.
* Retain normal resource limits for database connections, downstream concurrency, etc.

### AVOID

* Reactive programming solely because platform threads were historically expensive.
* Assuming enabling virtual threads removes downstream capacity constraints.

Reference, rather than duplicate, the Java concurrency guidance.
