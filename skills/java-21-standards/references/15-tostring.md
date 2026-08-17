## 15. `toString()`

### SHOULD

* Make diagnostic representations useful.
* Include identifying/contextual state where appropriate.

### AVOID

* Huge recursive representations.
* Expensive work inside `toString()`.

### NEVER

* Expose passwords, credentials, tokens or other secrets through `toString()`.

