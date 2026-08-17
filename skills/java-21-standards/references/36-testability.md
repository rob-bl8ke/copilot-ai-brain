## 36. Testability

Even though the testing framework belongs elsewhere, these design standards belong here.

### SHOULD

* Make behavior deterministic where possible.
* Keep external effects at clear boundaries.
* Make dependencies explicit.
* Treat clocks/random generators/external systems as controllable dependencies when business behavior depends upon them.
* Test through meaningful APIs.

### AVOID

* Global mutable state.
* Private-method testing.
* Relaxing production encapsulation solely for tests.
* Designing everything around mocking.

