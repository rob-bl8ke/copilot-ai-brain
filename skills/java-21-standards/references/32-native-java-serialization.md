## 32. Native Java serialization

### SHOULD

* Prefer explicit serialization/interchange mechanisms for new designs.

### AVOID

* Adding `Serializable` merely "in case it is needed later."
* Native serialization for persistence formats or service contracts.

### NEVER

* Deserialize arbitrary untrusted native Java serialization streams.

