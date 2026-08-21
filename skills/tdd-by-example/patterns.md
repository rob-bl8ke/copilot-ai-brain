# Pattern catalog (Part III of the book)

Reference vocabulary for explaining TDD design choices. The main SKILL.md covers everything needed to run the cycle; this file is for when the user wants the named patterns or a deeper rationale.

## Testing patterns (how to choose and shape a test)

- **One Step Test** — pick the next test based on what moves the implementation one small step forward, not on what's most complete or most interesting.
- **Child Test** — if a test feels too big to satisfy quickly, write a smaller "child" test that isolates part of the behavior, get that green, then return to the original.
- **Evident Data** — structure test data and assertions so the relationship between input and expected output is visible without computation (e.g. literal expected values rather than expressions).
- **Test List** — keep a running scratch list of tests-to-write, adding to it as new cases occur to you rather than chasing them mid-test.

## Red bar patterns (getting from failing to passing)

- **Fake It** — return a hardcoded literal to get green fast; defer the real generalization until a second test forces it.
- **Triangulate** — add a second example with different concrete values specifically to force a hardcoded fake into a general rule. Use when the right abstraction isn't obvious yet.
- **Obvious Implementation** — when you're confident of the real logic and it's short, just write it directly instead of faking first.
- **Property-Based Testing** — declare the invariant the code must hold and let a framework (jqwik, Hypothesis, fast-check, proptest) generate inputs to find counterexamples. Extends Triangulate to cover wide input domains without hand-picking examples. Coexists with example-based tests rather than replacing them.

## Green bar / refactoring patterns

- **One to Many** — when a single value needs to become a collection of values (e.g. one currency amount becoming a sum of several), let a passing test guide the transition incrementally rather than redesigning up front.
- General duplication removal — the recurring driver of nearly every refactor in the book: duplication between test and code, or between two code paths, is treated as the primary signal for when and how to change the design.

## xUnit framework patterns (naming the roles in a test framework)

Useful vocabulary when discussing or building test infrastructure itself, not just using an existing one:

- **Test Method** — a single test case, typically a method whose name describes the behavior under test.
- **Fixture** — the shared setup/state a test needs, usually established in a `setUp`-style method and torn down afterward.
- **Assertion** — a check that fails the test with a clear message when an expectation isn't met.
- **Test Suite** — a collection of test methods/cases run together, aggregating results.

## Design patterns, viewed through a TDD lens

Beck revisits familiar OO design patterns not as things to apply up front, but as shapes that tend to *emerge* from repeated duplication-removal under test:

- **Value Object** — immutable objects compared by value rather than identity (arises from needing reliable equality checks in tests).
- **Composite** — treating a single item and a collection of items through the same interface (arises from wanting `Money` and `Sum` to be usable interchangeably).
- **Template Method / Imposter (Null Object)** — arise from removing conditional duplication around "does this thing exist / apply or not."

The point of this section isn't the patterns themselves — it's the reminder that in this workflow, patterns are a *result* of following the cycle, not a plan imposed on it.

## Post-Beck extensions

Patterns and techniques that emerged after the book and have proven durable enough to enter mainstream TDD practice:

- **Outside-In / Double Loop** (Freeman & Pryce, 2009) — start with a failing acceptance test, then drive inner unit-test loops to make it pass. The outer test defines "done" for a feature slice; the inner loops build each collaborator. Preferred when the feature cuts across layers.
- **Characterization Test** (Feathers, 2004) — pin existing behavior before changing legacy code. Write a test, let it fail, use the actual output as the expected value. The goal is a safety net, not correctness verification. Bridge from untested code to the normal TDD cycle.
- **Test Desiderata** (Beck, 2019) — twelve properties of good tests (isolated, composable, deterministic, specific, fast, writable, readable, behavioral, structure-insensitive, predictive, inspiring, automated). A diagnostic checklist when a test feels wrong but the reason isn't obvious.
