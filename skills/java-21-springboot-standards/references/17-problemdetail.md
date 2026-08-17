## 17. `ProblemDetail`

For modern Spring MVC applications:

### SHOULD

Consider Spring's RFC-style `ProblemDetail` support for consistent API error representations rather than inventing ad hoc error structures.

### AVOID

Different error JSON formats for every controller.

This could live in a separate Spring REST reference if we later want to keep the core skill smaller.
