## 25. Repository/data layer

The core Spring skill should remain light here.

### SHOULD

* Keep persistence behind clear application/domain boundaries.
* Allow Spring's repository abstractions where the chosen persistence technology supports them.

### AVOID

* Database-specific implementation leaking through every layer.
* Calling repositories directly from controllers.

But things such as:

* JPA entity design;
* fetch strategies;
* Hibernate;
* N+1;
* optimistic locking;
* JDBC;
* Spring Data query methods;

should go into something like:

```text
java-spring-data-standards
```

not this core skill.
