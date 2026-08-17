## 34. Mocking Spring

### SHOULD

* Mock collaborators at genuine boundaries.
* Prefer testing behavior over framework implementation.

### AVOID

Mocking:

* `ApplicationContext`;
* basic domain objects;
* every internal method;
* Spring itself.

### NEVER

Design production classes primarily to make mocking easier.

That remains consistent with our base Java standard.
