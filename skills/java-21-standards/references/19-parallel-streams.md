## 19. Parallel streams

### CONSIDER

* Parallel streams only after establishing that the operation is safe, sufficiently large and actually benefits.

### AVOID

* Parallel streams in request-handling/business code without measurement.
* Parallelizing workloads that contend on shared mutable state.
* Parallel streams around blocking I/O.

### NEVER

* Add `.parallel()` merely as a performance optimization without evidence.

