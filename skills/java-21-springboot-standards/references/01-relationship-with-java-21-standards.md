## 1. Relationship with `java-21-standards`

### MUST

* Apply `java-21-standards` first.
* Treat this skill as additive rather than replacement guidance.
* Prefer normal Java constructs when Spring adds no useful capability.
* Follow Spring Boot conventions where they simplify framework integration.
* Respect the project's pinned Java and Spring Boot versions.

### SHOULD

* Keep framework concerns toward application/infrastructure boundaries.
* Keep domain/business logic as ordinary Java wherever practical.
* Minimize unnecessary Spring coupling.
* Let Spring manage objects that genuinely participate in application infrastructure/lifecycle.

### AVOID

* Repeating vanilla Java rules here.
* Turning every Java class into a Spring bean.
* Adding Spring annotations merely because Spring is available.

### NEVER

* Override a base Java rule solely because "this is Spring".
