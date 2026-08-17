## 20. Lambdas

### SHOULD

* Keep lambdas short and comprehensible.
* Prefer standard functional interfaces where they accurately describe the operation.
* Use method references where they improve readability.

### CONSIDER

* A named method instead of a non-trivial lambda.
* A custom functional interface when the domain concept deserves a name.

### AVOID

* Large multiline lambdas.
* Stateful lambdas.
* Functional transformations that obscure straightforward imperative logic.

