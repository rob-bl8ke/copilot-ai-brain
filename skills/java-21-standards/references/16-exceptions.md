## 16. Exceptions

### MUST

* Preserve the original cause when translating an exception.
* Clean up acquired resources.
* Propagate interruption correctly.
* Keep exception contracts meaningful.

### SHOULD

* Catch an exception only when the current layer can handle, translate, enrich or deliberately terminate because of it.
* Include useful context in exception messages.
* Create domain exceptions when they add meaningful information.
* Use try-with-resources.

### CONSIDER

* Checked exceptions where callers can reasonably recover and the contract benefits from expressing this.
* Unchecked exceptions where recovery is not reasonably expected.

### AVOID

* `catch (Exception)` outside intentional application boundaries.
* Large custom exception hierarchies.
* Exception-driven normal control flow.
* Repeatedly logging and rethrowing the same exception at every layer.

### NEVER

* Silently swallow an exception.
* Catch `Throwable` in ordinary application logic.
* Use an empty `catch` block.

### Examples

**Preserve the cause when translating an exception**

```java
// WRONG — original cause discarded; root problem invisible in logs
try { repository.save(entity); }
catch (SQLException e) {
    throw new DataAccessException("Save failed"); // cause lost
}

// CORRECT — cause chain preserved
catch (SQLException e) {
    throw new DataAccessException("Save failed for id=" + entity.getId(), e);
}
```

**Log-and-rethrow at every layer produces duplicate log entries**

```java
// WRONG — same exception logged at service, facade, and controller layers
} catch (OrderException e) {
    log.error("Order processing failed", e);
    throw e; // logged again upstream
}

// CORRECT — log once at the boundary that handles it, or just rethrow
} catch (OrderException e) {
    throw e;
}
```

