## 5. Records

### SHOULD

* Use records for transparent value/data carriers when their semantics match the problem.
* Validate record invariants in the compact constructor where necessary.
* Treat record components as part of the public API.

### CONSIDER

* Records for domain value objects.

### AVOID

* Records for heavily stateful entities.
* Records when component identity and structural equality do not match the domain.
* Records purely to reduce boilerplate when normal class semantics are actually needed.

