## 13. Controllers

Assuming Spring MVC/web is present:

### MUST

* Treat request input as untrusted.
* Validate external input.
* Return appropriate HTTP semantics.

### SHOULD

Controllers should primarily:

1. accept HTTP input;
2. validate/map it;
3. invoke application behavior;
4. translate the result into HTTP output.

For example:

```java
@RestController
@RequestMapping("/customers")
class CustomerController {

    private final CustomerService customerService;

    CustomerController(CustomerService customerService) {
        this.customerService = customerService;
    }

    @PostMapping
    ResponseEntity<CustomerResponse> create(
            @Valid @RequestBody CreateCustomerRequest request) {

        var customer = customerService.create(request);

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(CustomerResponse.from(customer));
    }
}
```

### AVOID

Controllers containing:

* database queries;
* substantial business logic;
* transaction orchestration;
* complex calculations;
* infrastructure logic.

### NEVER

Treat the controller as the application's service layer.
