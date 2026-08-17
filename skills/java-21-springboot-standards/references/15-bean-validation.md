## 15. Bean Validation

### SHOULD

Use Jakarta Bean Validation for declarative boundary validation where appropriate.

```java
public record CreateOrderRequest(
        @NotNull UUID customerId,
        @Positive int quantity) {
}
```

### SHOULD

* Validate external request/configuration boundaries.
* Keep domain invariants enforced by the domain as well where necessary.

### AVOID

* Treating Bean Validation annotations as a substitute for domain invariants.
* Revalidating everything at every layer.

This directly follows our base Java "validation at boundaries + preserve invariants" principle.
