# Types And Data

Use when changing annotations, data models, collections, mutability, strings, numbers, dates, equality, or object representation.

## MUST

- Use `is` and `is not` for `None`, `True`, `False`, and other singletons.
- Distinguish absence from falsiness when empty strings, zero, empty containers, or `False` are valid values.
- Avoid mutable default argument values; use `None` plus initialization or `dataclasses.field(default_factory=...)`.
- Keep objects hashable only when their equality-relevant state is immutable.
- Preserve equality, ordering, and hashing contracts when implementing `__eq__`, ordering methods, or `__hash__`.
- Use timezone-aware datetimes for real instants; do not mix naive and aware datetimes in comparisons or persistence boundaries.
- Decode bytes to `str` at boundaries using an explicit encoding when data is not already guaranteed text.

## SHOULD

- Use built-in generic syntax in Python 3.11: `list[str]`, `dict[str, int]`, `tuple[int, ...]`.
- Use `X | None` and `A | B` unions instead of `Optional[X]` and `Union[A, B]` in new Python 3.11 code, unless local style differs.
- Use `typing.Self` for methods and classmethods returning instances of the current class.
- Use `Required` and `NotRequired` for mixed-presence `TypedDict` fields.
- Use `LiteralString` for APIs that should accept only statically known strings, such as command or query templates.
- Prefer annotations on public boundaries, complex return values, and non-obvious local variables.
- Prefer `dataclass` for simple data carriers with behavior-free or light behavior models.
- Prefer `frozen=True` dataclasses and tuples for value objects that should not mutate.
- Use `Enum`, `StrEnum`, or `Flag` when the domain is a closed set of named values.
- Use `decimal.Decimal` for decimal financial calculations and `fractions.Fraction` for exact rational arithmetic.
- Use `datetime.UTC` or `datetime.timezone.utc` for UTC-aware datetimes.
- Prefer `collections.abc` interfaces such as `Mapping`, `Sequence`, and `Iterable` for parameters that do not need a concrete collection.

## CONSIDER

- Use `NamedTuple` or frozen dataclasses for lightweight immutable records.
- Use `slots=True` on dataclasses or classes when many instances are created and dynamic attributes are unnecessary.
- Use `typing.Protocol` for structural contracts that avoid unnecessary inheritance coupling.
- Use `NewType` for semantically distinct primitive identifiers when type checking would prevent real mistakes.
- Use `TypedDict` for dictionaries crossing boundaries with a known key schema.

## AVOID

- Over-annotating obvious local variables when it adds noise without improving clarity.
- Using `Any` to silence type problems without preserving a boundary or documenting why type information is unavailable.
- Using `list` or `dict` as default values in dataclasses without `default_factory`.
- Comparing types with `type(x) is Y` when `isinstance(x, Y)` correctly models the contract.
- Using floating point for money or exact decimal quantities.
- Building strings through repeated concatenation in performance-sensitive loops; collect parts and `''.join(...)`.

## NEVER

- Rely on truthiness when the code specifically needs to know whether a value is `None`.
- Make a mutable object hashable based on mutable state.
- Use Python 2 typing comment style in new Python 3.11 code unless maintaining an unannotated legacy file.

## Agent Guardrails

- Do not add a type checker, runtime validation library, or typing dependency from this skill alone.
- Do not convert whole modules to type hints when asked for a localized behavioral change.
- Let framework and serialization skills decide DTO, schema, ORM, and validation-library conventions.
