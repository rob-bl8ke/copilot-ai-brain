## 14. Equality and hashing

### MUST

* Override `hashCode()` whenever `equals()` is overridden.
* Preserve the `equals()` contract.
* Avoid mutating fields involved in hashing while the object is being used as a key/set member.

### SHOULD

* Model equality according to domain semantics.
* Prefer records where their generated structural equality exactly matches the required semantics.

### AVOID

* Identity equality for value objects.
* Including volatile/mutable operational state in value equality.

### NEVER

* Override `equals()` without a compatible `hashCode()` implementation.

