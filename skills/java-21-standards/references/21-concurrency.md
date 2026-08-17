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

