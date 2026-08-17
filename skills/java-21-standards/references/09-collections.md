## 9. Collections

### MUST

* Use generic collection types rather than raw types.
* Respect collection contracts concerning mutability, ordering and uniqueness.

### SHOULD

* Expose APIs using interfaces such as `List`, `Set` and `Map`.
* Select the collection based on required semantics.
* Return empty collections instead of `null`.
* Use `List.of`, `Set.of`, `Map.of`, etc. for small immutable collections.
* Use `copyOf()` where an immutable snapshot is intended.
* Use `EnumSet`/`EnumMap` for enum-keyed data when appropriate.

### CONSIDER

* Java 21 sequenced collection interfaces where first/last/reversed semantics matter.
* `computeIfAbsent`, `merge`, etc. for straightforward map operations.

### AVOID

* Depending on iteration order where the type doesn't guarantee it.
* Returning an internal mutable collection.
* Choosing `List` automatically when uniqueness or lookup semantics suggest another type.

