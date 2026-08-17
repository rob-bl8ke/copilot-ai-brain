## 16. Exceptions

### MUST

* Preserve the original cause when translating an exception.
* Clean up acquired resources.
* Propagate interruption correctly.
* Keep exception contracts meaningful.

### SHOULD

* Catch an exception only when the current layer can handle, translate, enrich or deliberately terminate because of it.
* Include useful context in exception messages.
* Create domain exceptions when they add meaningful information.
* Use try-with-resources.

### CONSIDER

* Checked exceptions where callers can reasonably recover and the contract benefits from expressing this.
* Unchecked exceptions where recovery is not reasonably expected.

### AVOID

* `catch (Exception)` outside intentional application boundaries.
* Large custom exception hierarchies.
* Exception-driven normal control flow.
* Repeatedly logging and rethrowing the same exception at every layer.

### NEVER

* Silently swallow an exception.
* Catch `Throwable` in ordinary application logic.
* Use an empty `catch` block.

