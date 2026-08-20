## 12. Numbers

### MUST

* Use an appropriate numeric representation for the precision required by the domain.
* Define rounding explicitly when business rules depend upon it.

### SHOULD

* Prefer primitive numeric types unless object/null/generic semantics require boxed values.
* Use `BigDecimal` for exact decimal financial calculations.
* Prefer `BigDecimal.valueOf(double)` rather than `new BigDecimal(double)` when converting a double.

### CONSIDER

* Overflow-safe methods such as `Math.addExact()` when overflow would represent a programming/data error.

### AVOID

* Gratuitous boxing/unboxing.
* Implicit narrowing conversions.
* Magic numbers: unnamed numeric literals embedded in logic instead of a named constant or a self-explanatory domain type.

### NEVER

* Use floating-point arithmetic where exact monetary values are required.
