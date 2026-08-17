## 17. Resource management

### MUST

* Close owned resources.
* Do not close resources owned by another component unless explicitly part of the contract.

### SHOULD

* Use try-with-resources with `AutoCloseable`.
* Keep acquisition and cleanup ownership clear.
* Ensure executor services and other lifecycle resources have an explicit shutdown strategy.

### AVOID

* Manual `finally` cleanup when try-with-resources handles the requirement.
* Relying on garbage collection for timely resource cleanup.

### NEVER

* Use finalization as a resource management strategy.

