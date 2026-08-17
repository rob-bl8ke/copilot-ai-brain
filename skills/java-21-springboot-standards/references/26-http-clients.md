## 26. HTTP clients

Similarly, core rules only.

### SHOULD

* Centralize configuration of outbound HTTP clients.
* Configure explicit timeouts.
* Treat downstream failure as expected distributed-system behavior.
* Use typed request/response models.

### AVOID

* Constructing HTTP clients per request.
* Hard-coded endpoint URLs.
* HTTP calls buried inside domain objects.

Detailed `RestClient`, `WebClient`, retry, resilience etc. could become another reference/skill.
