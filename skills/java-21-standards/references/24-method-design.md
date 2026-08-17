## 24. Method design

### SHOULD

* Make a method perform one coherent operation.
* Keep parameters meaningful and manageable.
* Use guard clauses where they meaningfully reduce nesting.
* Keep abstraction levels coherent.
* Name methods according to intent.
* Keep side effects clear.

### CONSIDER

* Parameter objects where parameters represent one conceptual group.
* Extracting a method where the extracted operation deserves a meaningful name.

### AVOID

* Boolean flag arguments such as:

```java
saveCustomer(customer, true, false);
```

* Deep nesting.
* Very long parameter lists.
* Methods whose behavior changes radically depending on unrelated flags.

### NEVER

* Enforce arbitrary method-size rules such as "all methods must be fewer than 20 lines."

