## 19. Self-invocation / proxy awareness

This is an important Spring-specific trap for agents.

### MUST

Understand that some Spring features are applied via proxies.

### AVOID

Designs dependent upon:

```java
this.someTransactionalMethod();
```

triggering proxy-based behavior such as a normal external bean invocation would.

### SHOULD

* Keep proxied concerns at meaningful bean boundaries.
* Prefer straightforward service decomposition over clever proxy workarounds.

This deserves explicit mention because generated Spring code commonly gets it wrong.
