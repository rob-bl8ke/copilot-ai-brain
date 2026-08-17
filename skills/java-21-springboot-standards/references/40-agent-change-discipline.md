## 40. Agent change discipline

### MUST

* Preserve the existing Spring Boot version.
* Preserve Java 21.
* Respect existing Spring conventions in the repository.
* Understand an annotation before introducing it.
* Maintain bean wiring correctness.
* Maintain configuration compatibility.
* Keep tests/build working.

### SHOULD

* Prefer Boot conventions over custom framework plumbing.
* Make the smallest Spring-aware change.
* Reuse existing configuration/components where appropriate.
* Match existing dependency-management practices.
* Use existing application architecture rather than inventing another one.

### AVOID

* Opportunistic Spring upgrades.
* Dependency version overrides.
* Broad component scans.
* unrelated configuration changes.
* turning non-Spring Java into Spring-managed code without reason.
* loading the entire application context in every test.
* adding framework features speculatively.

### NEVER

* Upgrade Spring Boot or managed dependencies silently.
* Introduce a Spring abstraction merely because it exists.
* Hide broken design behind annotations.
