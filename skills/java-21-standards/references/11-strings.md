## 11. Strings

### MUST

* Use `.equals()` or an equivalent value comparison for String equality.

### SHOULD

* Use ordinary `+` concatenation when it is the clearest expression.
* Use `StringBuilder` for repeated string mutation, particularly inside loops.
* Use text blocks for naturally multiline content.
* Specify encoding at external boundaries where encoding forms part of the contract.

### CONSIDER

* `Locale.ROOT` for machine-readable case transformations.

### AVOID

* Manually concatenating filesystem paths.
* Creating a `StringBuilder` for every tiny concatenation.

### NEVER

* Use `==` to perform logical String equality.

