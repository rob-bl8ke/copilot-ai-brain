## 12. Business/domain code

### SHOULD

Prefer:

```java
public final class PriceCalculator {
    ...
}
```

when the class doesn't need Spring.

Instead of automatically doing:

```java
@Component
public class PriceCalculator {
    ...
}
```

### SHOULD

* Keep pure domain calculations as pure Java.
* Pass dependencies explicitly.
* Keep Spring-specific infrastructure at appropriate boundaries.

### CONSIDER

Making an application service a Spring-managed bean because Spring manages its dependencies/lifecycle.

### AVOID

* `ApplicationContext` in domain code.
* Spring annotations on value objects.
* Framework APIs embedded throughout domain logic.

This directly preserves our vanilla Java skill.
