## 22. Virtual threads

### SHOULD

* Consider virtual threads for high-concurrency workloads dominated by blocking I/O.
* Write straightforward blocking code where virtual threads provide sufficient scalability.
* Constrain the scarce resource rather than arbitrarily pooling virtual threads.

### CONSIDER

* `Executors.newVirtualThreadPerTaskExecutor()` for independent blocking tasks.

### AVOID

* Treating virtual threads as a CPU-performance feature.
* Replacing every platform thread blindly.
* ThreadLocal-heavy designs when extremely large virtual-thread counts are expected.

### NEVER

* Create a fixed-size pool of virtual threads simply because platform threads were traditionally pooled.

### Examples

**Bound the scarce resource, not the threads**

```java
// WRONG — fixed virtual-thread pool defeats the purpose
ExecutorService exec = Executors.newFixedThreadPool(100,
    Thread.ofVirtual().factory());

// CORRECT — one virtual thread per task; semaphore caps the real constraint
Semaphore dbSlots = new Semaphore(20); // e.g. DB connection pool size
try (var exec = Executors.newVirtualThreadPerTaskExecutor()) {
    for (var request : requests) {
        exec.submit(() -> {
            dbSlots.acquireUninterruptibly();
            try { handle(request); }
            finally { dbSlots.release(); }
        });
    }
} // close() waits for all tasks to finish
```

