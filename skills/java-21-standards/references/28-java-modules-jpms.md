## 28. Java modules / JPMS

### CONSIDER

* JPMS when strong module boundaries, distribution or encapsulation genuinely benefit the application.

### AVOID

* Introducing JPMS solely because the runtime supports it.
* Massive `opens`/`exports` declarations that eliminate its encapsulation benefit.

This should intentionally remain low-priority in the skill.

