## 23. Filesystem and I/O

### MUST

* Correctly close streams/resources.
* Treat untrusted paths as untrusted input.

### SHOULD

* Prefer `Path` and `Files`.
* Use `Path.resolve()` instead of string concatenation.
* Stream large data instead of unnecessarily loading it fully into memory.
* Be explicit about encoding where it is part of the interface.

### AVOID

* New code based primarily on legacy `File`.
* Assuming Unix or Windows separators.
* Loading arbitrarily large input using convenience APIs without considering memory.

