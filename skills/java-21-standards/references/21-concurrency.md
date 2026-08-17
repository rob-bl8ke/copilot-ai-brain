## 21. Concurrency

### MUST

* Correctly synchronize access to shared mutable state.
* Respect Java Memory Model visibility requirements.
* Preserve interruption unless intentionally consumed at a defined boundary.
* Manage executor lifecycle.

### SHOULD

* Minimize shared mutable state.
* Prefer immutable data exchanged between tasks.
* Prefer `java.util.concurrent` abstractions over low-level coordination.
* Prefer concurrent collections where they match the problem.
* Keep lock scope small.

### CONSIDER

* Atomic classes for true atomic-state problems.
* Explicit locks when they provide semantics unavailable through simpler synchronization.

### AVOID

* Blocking external calls while holding locks.
* Nested lock acquisition.
* Manual low-level thread coordination.
* Shared mutable collections protected by ad hoc synchronization where a concurrent abstraction suffices.

### NEVER

* Swallow `InterruptedException`.
* Assume `volatile` makes compound operations atomic.

### Examples

**`volatile` does not make compound operations atomic**

```java
// WRONG — volatile only guarantees visibility, not atomicity
private volatile int count = 0;
void increment() { count++; } // read-modify-write: two threads can both read 0 and both write 1

// CORRECT
private final AtomicInteger count = new AtomicInteger(0);
void increment() { count.incrementAndGet(); }
```

**`InterruptedException` must not be swallowed**

```java
// WRONG — interrupt signal is silently lost
try { Thread.sleep(500); }
catch (InterruptedException e) { /* ignored */ }

// CORRECT — restore interrupt status before propagating
try { Thread.sleep(500); }
catch (InterruptedException e) {
    Thread.currentThread().interrupt();
    throw new ProcessingException("Interrupted during wait", e);
}
```

