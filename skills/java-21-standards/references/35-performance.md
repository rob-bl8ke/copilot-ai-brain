## 35. Performance

### SHOULD

* Choose suitable algorithms and data structures.
* Measure performance before making non-obvious optimizations.
* Pay attention to complexity on potentially large collections.
* Keep obvious unnecessary repeated work out of loops.

### CONSIDER

* Allocation/boxing optimizations in demonstrated hot paths.
* Specialized data structures where profiling supports them.

### AVOID

* Micro-optimizing normal business code.
* Sacrificing maintainability for theoretical speed.
* Optimizing based solely on intuition.

### NEVER

* Claim a performance improvement without evidence when the change makes the implementation meaningfully more complex.

