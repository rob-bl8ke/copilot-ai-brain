## 10. Generics

### MUST

* Do not use raw collection/generic types in new code.
* Keep unchecked operations isolated and justified.

### SHOULD

* Prefer compile-time type safety over casting.
* Follow PECS where applicable.
* Use bounded wildcards to make APIs appropriately flexible.

### CONSIDER

* Generic helper methods when several actual types share the same algorithm.

### AVOID

* Complex generic hierarchies without a concrete benefit.
* Generic abstractions introduced merely for hypothetical reuse.
* Wildcards that make APIs harder rather than easier to use.

### NEVER

* Blanket-suppress unchecked warnings across a class/project instead of addressing their source.

