## 24. Scheduling

If Spring scheduling is being used:

### SHOULD

* Keep scheduled entry points thin.
* Delegate actual behavior to services.
* Make schedules configurable where deployment needs vary.
* Design scheduled work to tolerate duplicate/overlapping execution where relevant.

### AVOID

```java
@Scheduled(...)
public void doEverything() {
    // 300 lines
}
```

### NEVER

Assume multiple application instances magically coordinate scheduled work.

Distributed scheduling/locking belongs in a separate architectural skill.
