## 5. Spring stereotypes

### SHOULD

Use the annotation conveying the component's role:

```java
@Component
@Service
@Repository
@Controller
@RestController
```

### AVOID

* Annotating every class with `@Component`.
* Using `@Service` for objects that contain no application/service responsibility.
* Putting Spring annotations on simple value objects, DTOs, records or domain entities without need.

### NEVER

* Turn domain models into Spring beans simply for convenient access.
