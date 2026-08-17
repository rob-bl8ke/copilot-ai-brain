## 18. Transaction boundaries

If Spring transaction support is present:

### SHOULD

* Place transaction boundaries around coherent application operations.
* Usually place `@Transactional` at service/application boundaries rather than controllers.
* Keep transactions as short as practical.

### AVOID

* `@Transactional` everywhere.
* Transactions around remote HTTP calls unless transaction semantics have explicitly been designed.
* Long-running transactions.
* Controller-level transaction boundaries by default.

### NEVER

Assume `@Transactional` magically makes distributed operations atomic.

This section covers framework-level transaction boundaries. Persistence details belong in a more specific Spring Data/JPA/JDBC skill.
