## 7. Null handling

### MUST

* Never return `null` from a method declared to return `Optional`.
* Clearly distinguish required values from optional values.
* Handle possible `null` values deliberately rather than relying on accidental `NullPointerException`s.

### SHOULD

* Prefer non-null references as the normal contract.
* Validate required arguments near the boundary.
* Use `Objects.requireNonNull()` where it communicates an invariant clearly.
* Return empty collections rather than `null` collections.

### AVOID

* Passing `null` as an implicit signal or command.
* Returning `null` where absence is a normal part of the API.

### NEVER

* Catch `NullPointerException` as ordinary control flow.

