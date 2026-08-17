## 14. Request/response DTOs

### SHOULD

* Keep transport models distinct where the HTTP contract differs from the domain.
* Consider records for immutable request/response DTOs.
* Validate request DTOs at the boundary.

Example:

```java
public record CreateCustomerRequest(
        @NotBlank String name,
        @Email String email) {
}
```

### AVOID

* Exposing persistence entities directly as API contracts.
* Reusing one "universal DTO" for unrelated API operations.
* DTO-to-DTO abstraction layers that add no value.

The base Java record guidance works naturally here.
