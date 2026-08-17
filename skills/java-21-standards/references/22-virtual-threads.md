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


