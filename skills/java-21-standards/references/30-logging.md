## 30. Logging

### MUST

* Never log secrets/credentials.

### SHOULD

* Log operationally meaningful information.
* Preserve exception information when logging failures.
* Include enough context to diagnose the event.

### AVOID

* `System.out.println()` as application logging.
* Logging an exception at every layer through which it propagates.
* Huge objects or entire request payloads without justification.

Notice that this doesn't mandate SLF4J or another library.

