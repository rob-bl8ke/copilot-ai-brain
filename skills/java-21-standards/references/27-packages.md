## 27. Packages

### SHOULD

* Keep packages cohesive.
* Maintain sensible dependency direction.
* Keep package visibility narrow.
* Package related domain concepts together where practical.

### CONSIDER

* Package-by-feature/domain rather than purely package-by-technical-layer.

### AVOID

* Giant `util`, `common`, `misc`, or `helpers` dumping-ground packages.
* Cyclic package dependencies.

