## 38. Third-party dependencies

This is especially important for the skill.

### SHOULD

* Prefer JDK functionality when it cleanly solves a modest problem.
* Follow the repository's established dependency policy.

### CONSIDER

* A dependency when it significantly reduces complexity or risk.

### AVOID

* Pulling in a library for a trivial operation available in the JDK.
* Reimplementing a complex well-solved problem merely to avoid a reasonable dependency.

So the rule should **not** simply be "always use the JDK."

