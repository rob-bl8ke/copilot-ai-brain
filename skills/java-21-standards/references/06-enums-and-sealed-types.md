## 6. Enums and sealed types

### SHOULD

* Prefer enums over strings for known finite values.
* Put behavior on enums where it naturally belongs.

### CONSIDER

* Sealed interfaces/classes for closed domain alternatives.
* Exhaustive pattern-switch handling over sealed hierarchies.

### AVOID

* Giant enums acting as miscellaneous global registries.
* String comparisons representing what is really an enumerated domain concept.

