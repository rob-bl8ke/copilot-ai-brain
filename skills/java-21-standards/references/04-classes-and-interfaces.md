## 4. Classes and interfaces

### MUST

* Follow inheritance contracts when overriding behavior.
* Use the narrowest visibility compatible with the API requirement.

### SHOULD

* Prefer composition over inheritance.
* Keep implementation classes private/package-private when outside access isn't required.
* Design interfaces around meaningful capabilities or contracts.
* Keep inheritance shallow.
* Make classes `final` when extension would violate their intended design and extensibility isn't part of the contract.

### CONSIDER

* Static factory methods when construction intent benefits from a meaningful name.
* Builders for complex object construction.
* Sealed hierarchies for finite type systems.

### AVOID

* An interface for every implementation.
* Abstract base classes created solely for anticipated reuse.
* Public APIs that expose implementation details.
* Empty marker interfaces without a meaningful reason.

