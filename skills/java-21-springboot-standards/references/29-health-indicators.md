## 29. Health indicators

### SHOULD

* Distinguish application liveness from dependency readiness where deployment infrastructure uses those semantics.
* Keep health checks cheap.

### AVOID

* Expensive database/business operations on every health request.
* Making liveness dependent on every downstream dependency.
* Health indicators with side effects.
