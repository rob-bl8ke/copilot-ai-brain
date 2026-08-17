## 37. Legacy Java APIs and practices

### SHOULD

Prefer modern equivalents in new code.

### AVOID

* `Vector`
* `Hashtable`
* `Stack`
* `Enumeration`
* `Date`
* `Calendar`
* `StringBuffer` when synchronization isn't required
* raw types
* anonymous classes where lambdas clearly suffice
* manual resource cleanup
* old `instanceof` + cast boilerplate

### NEVER

* Finalizers for resource management.
* Introduce known-obsolete APIs into greenfield code without an interoperability requirement.

