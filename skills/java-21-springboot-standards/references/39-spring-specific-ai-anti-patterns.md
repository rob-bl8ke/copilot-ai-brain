## 39. Spring-specific AI anti-patterns

### AVOID

An agent automatically creating:

```text
FooController
FooService
FooServiceImpl
FooRepository
FooRepositoryImpl
FooMapper
FooDto
FooEntity
FooConfiguration
FooException
FooExceptionHandler
```

for every feature.

Instead:

> Create only the components justified by the requirement.

Avoid automatically adding:

* `@Transactional`;
* `@Async`;
* `@Cacheable`;
* `@Retryable`;
* interfaces;
* DTOs;
* mappers;
* configuration classes;
* profiles;
* event publishers.

Each must solve an actual problem.
