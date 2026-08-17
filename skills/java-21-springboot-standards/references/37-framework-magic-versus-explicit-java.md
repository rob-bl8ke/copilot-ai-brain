## 37. Framework magic versus explicit Java

### SHOULD

Prefer Spring convention where it eliminates infrastructure boilerplate.

Prefer ordinary Java where it expresses business behavior more clearly.

That gives us a useful dividing line:

```text
Framework concern        → Spring idiom
Business/domain concern  → Java idiom
```

For example:

```text
Dependency wiring        → Spring
Configuration binding    → Spring
HTTP routing             → Spring
Lifecycle                → Spring

Calculation              → Java
Domain invariants        → Java
Value objects            → Java
Algorithms               → Java
```

This might be the **single most important architectural principle** of the combined skills.
