## 20. Bean scope and state

### MUST

Remember that ordinary Spring beans are singleton-scoped by default.

### SHOULD

* Keep singleton beans stateless where practical.
* Ensure mutable state is thread-safe if it exists in singleton beans.

### AVOID

```java
@Service
class OrderService {
    private Order currentOrder;
}
```

unless this is intentionally synchronized shared application state—which is extraordinarily unusual.

This strongly reinforces our Java concurrency rules.
