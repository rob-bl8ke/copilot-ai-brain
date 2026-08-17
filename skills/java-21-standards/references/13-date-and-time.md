## 13. Date and time

### MUST

* Use a date/time type matching the actual semantics of the value.
* Make timezone/offset semantics explicit where they matter.

### SHOULD

* Use `java.time`.
* Use `Instant` for machine timestamps.
* Use `LocalDate` for dates without times.
* Use `Duration` for elapsed time.
* Use `Clock` where the current time must be controllable in tests.
* Use `DateTimeFormatter` for formatting/parsing.

### CONSIDER

* `OffsetDateTime` or `ZonedDateTime` where offset/zone semantics are relevant.

### AVOID

* Scattered direct calls to `now()` in core business logic when time is an input to the behavior.
* Converting between date/time types without documenting the intended semantics.

### NEVER

* Introduce `Date` or `Calendar` into new Java 21 code without interoperability requirements.

