## 40. AI-specific overengineering guardrails

I'd make these highly visible.

### SHOULD

* Prefer existing code patterns over introducing new patterns.
* Use the simplest construct that expresses the requirement.
* Delete obsolete code when the requested change genuinely replaces it.

### AVOID

* Interface + abstract base + concrete implementation when one class suffices.
* Builders for tiny records/classes.
* Factories that merely call constructors.
* Wrapper classes with no domain semantics.
* Utility classes containing one trivial method.
* Excessive comments.
* Excessive validation deep inside trusted code.
* Premature caching.
* Premature concurrency.
* Premature asynchronous APIs.
* Design patterns added merely for architectural appearance.

### NEVER

* Generate code purely because "it might be needed later."

