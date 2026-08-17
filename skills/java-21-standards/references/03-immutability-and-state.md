## 3. Immutability and state

### MUST

* Protect mutable internal state from unintended external mutation.
* Avoid exposing mutable collections directly when callers are not meant to modify internal state.

### SHOULD

* Prefer immutable objects.
* Declare fields `final` where reassignment is unnecessary.
* Minimize shared mutable state.
* Establish valid object state during construction.
* Prefer immutable collection snapshots at boundaries where mutation isn't intended.
* Keep mutation local and obvious.

### CONSIDER

* Records for immutable value-oriented types.
* Defensive copies when passing mutable objects across ownership boundaries.

### AVOID

* Setter-heavy designs with no genuine need for mutability.
* Mutable static state.
* Objects that are valid only after a particular sequence of setters has been called.

