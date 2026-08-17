## 18. Transaction boundaries

If Spring transaction support is present:

### SHOULD

Place transaction boundaries at service/application operation boundaries, not at controllers or individual repository methods.

```java
@Service
class OrderService {

    @Transactional
    public Order placeOrder(PlaceOrderCommand command) {
        var order = Order.create(command);
        orderRepository.save(order);
        inventoryService.reserve(order);
        return order;
    }
}
```

### Read-only optimisation

For query-only operations, `@Transactional(readOnly = true)` allows the underlying provider to apply optimisations (Hibernate skips dirty-checking on read-only sessions):

```java
@Transactional(readOnly = true)
public Optional<Order> findById(UUID id) {
    return orderRepository.findById(id);
}
```

### Propagation

The default `REQUIRED` propagation is correct for almost all cases: joins an existing transaction, or creates one if none exists.

`REQUIRES_NEW` suspends the current transaction and opens a separate one. Use it deliberately — the two transactions commit independently, so partial success is possible and is a conscious design choice.

### SHOULD

* Place `@Transactional` at service/application boundaries rather than controllers.
* Keep transactions as short as practical.

### AVOID

* `@Transactional` on every class and method regardless of need.
* Transactions around remote HTTP calls unless compensating-transaction semantics have been explicitly designed.
* Long-running transactions holding locks while waiting on I/O.
* Controller-level transaction boundaries by default.

### NEVER

Assume `@Transactional` magically makes distributed operations atomic.

This section covers framework-level transaction boundaries. Persistence details belong in a more specific Spring Data/JPA/JDBC skill.
