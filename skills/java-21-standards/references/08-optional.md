## 8. Optional

### SHOULD

* Use `Optional<T>` primarily for return values where absence is expected and meaningful.
* Use `orElseGet()` when constructing the fallback is expensive or side-effectful.
* Prefer `map`, `flatMap`, `filter`, etc. when they genuinely improve clarity.

### CONSIDER

* Straightforward `isPresent()`/`isEmpty()` logic when it is clearer than a functional pipeline.

### AVOID

* `Optional` fields in ordinary domain objects.
* `Optional` parameters.
* Collections of `Optional` unless the semantics genuinely require them.
* Long Optional pipelines that obscure normal control flow.

### NEVER

* Return `null` instead of `Optional.empty()`.
* Call `Optional.get()` without establishing that a value exists.

