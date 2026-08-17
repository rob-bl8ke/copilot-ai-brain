## 31. Security

### MUST

* Treat externally supplied data as untrusted.
* Use secure APIs for security-sensitive operations.
* Prevent secrets from entering source code or logs.

### SHOULD

* Use `SecureRandom` when unpredictability matters.
* Validate user-controlled filesystem paths.
* Keep error responses from leaking sensitive implementation details.
* Prefer established cryptographic primitives.

### AVOID

* Native process execution when a safer Java API solves the problem.
* Deserialization mechanisms that instantiate arbitrary user-controlled object graphs.

### NEVER

* Implement home-grown cryptography for security-sensitive functionality.
* Hard-code production credentials.

