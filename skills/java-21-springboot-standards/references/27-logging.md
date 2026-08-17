## 27. Logging

The Java rule remains:

> don't mandate a logging implementation.

Spring adds:

### SHOULD

* Use the application's configured logging abstraction.
* Include useful operational context.
* Use appropriate levels.

### AVOID

* `System.out`.
* Logging the same exception at every layer.
* Huge request/response payload logging.
* framework debug logging enabled casually in production.

### NEVER

Log credentials or secrets.
