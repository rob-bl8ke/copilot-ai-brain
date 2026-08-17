## 39. Agent-specific change discipline

This is probably essential.

### MUST

* Respect existing repository conventions unless explicitly instructed otherwise.
* Limit changes to the requested scope.
* Preserve API compatibility unless the requirement explicitly changes it.
* Keep builds/tests compilable after the change where reasonably possible.

### SHOULD

* Produce the smallest coherent implementation.
* Reuse existing abstractions where they fit.
* Follow existing naming/package structure.
* Identify contradictions between the requested implementation and existing code instead of silently inventing a new convention.

### AVOID

* Opportunistic refactoring unrelated to the task.
* Reformatting unrelated files.
* Adding dependencies unnecessarily.
* Creating unused extension points.
* Generating placeholder abstractions for hypothetical future requirements.
* Modernizing unrelated code merely because a newer Java feature exists.

### NEVER

* Invent architectural requirements not present in the task/repository.
* Change public behavior silently.
* Suppress compiler warnings simply to produce a clean build.

