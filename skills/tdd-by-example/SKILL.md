---
name: tdd-by-example
description: Guides Claude through Kent Beck's Test-Driven Development workflow (Red-Green-Refactor, Fake It, Triangulate, Obvious Implementation) when writing or modifying code with real, executable tests. Use this skill whenever the user asks to "TDD" something, "write tests first," "test-driven," build a function/class/feature "with tests," fix a bug "with a regression test," or describes new behavior to implement in a codebase where a test runner is available or can be set up — even if they don't say the words "test-driven development" explicitly. Also use it when the user asks Claude to review whether existing code was built test-first, or to convert an existing implementation into a test-first workflow going forward. Do NOT use for one-off scripts, throwaway data analysis, or pure prototypes where the user has said speed matters more than a test suite — see the Escape Hatch section instead.
---

# Test-Driven Development, by Example

This skill encodes the workflow from Kent Beck's *Test-Driven Development: By Example*. The core claim of the book, and of this skill: working in tiny test-first steps produces better-designed code *and* gets you there faster than it feels like it should, because you spend less time debugging and redesigning later. The discipline is the point — skipping steps to "go faster" is almost always where it breaks down.

Claude has a bash tool and can actually run tests. This skill only works if Claude runs them for real at each step, not narrates what would probably happen. A red bar Claude didn't watch happen, and a green bar Claude didn't verify, don't count.

## The core cycle

Every change to behavior goes through this loop, in this order, without skipping steps:

```
1. RED      Write one small test for behavior that doesn't exist yet. Run it. Watch it fail.
2. GREEN    Write the minimum code to make that test pass. Run it. Watch it pass.
             Nothing else. Don't handle cases the test doesn't demand yet.
3. REFACTOR Clean up duplication or awkward structure, keeping all tests green.
             Run the full suite after each small refactor, not just at the end.
4. REPEAT   Pick the next test from the list. Go back to 1.
```

Two rules underlie the whole cycle, and most process questions resolve by asking which rule is at stake:

- **Don't write a line of production code without a failing test that demands it.** If there's no red bar driving it, it doesn't get written yet.
- **Remove duplication as soon as you see it** — between test and code, or between two pieces of code. Duplication is the signal that a design decision is overdue, not a cosmetic issue to defer.

## Before starting: make a test list

Before writing the first test, jot down a short list of test cases / behaviors to cover — a scratch to-do list, not a spec. Show it to the user briefly (a few lines, not a formal document). Example:

```
Test list for `parseDuration`:
- [ ] "5m" -> 300 seconds
- [ ] "1h" -> 3600 seconds
- [ ] "1h30m" -> 5400 seconds
- [ ] invalid input -> raises/throws
- [ ] empty string -> raises/throws
```

Add to this list as new cases occur to you mid-cycle rather than chasing them immediately — write them down and stay focused on the current test. Cross items off as they go green. This keeps steps small and stops "just one more thing" scope creep inside a single red-green-refactor loop.

**The list is English, not code, and that distinction matters.** Writing five bullet points costs nothing and is encouraged — planning ahead is fine. Writing five *test functions* into the test file before running any of them is not, even though it feels like the same kind of "getting organized" — it collapses five red-green loops into one, which is the exact thing the cycle exists to prevent. The tell is the artifact: a checklist item costs you nothing to have been wrong about; a written test function you haven't run yet is a claim about behavior you haven't checked. Only one test list item should ever be "in progress" — turned into actual test code — at a time. If you notice you're about to add a second test function while the first hasn't been run yet, stop and run the first one first.

## Picking each test: keep steps small

Choose the *next* test, not the hardest or most complete one. If a test feels too big to get to green quickly, that's a signal to write a smaller one first (a **Child Test**) rather than pushing through. Prefer boring, obvious inputs first, and work toward edge cases and errors once the core shape of the solution exists.

Make the test's expected value **obvious at a glance** — a reader shouldn't have to compute anything to check it. `assertEqual(parse("5m"), 300)` is evident; `assertEqual(parse("5m"), 5 * 60)` makes the reader redo the arithmetic the test was supposed to already do.

## Getting to green: three moves

These are the three legitimate ways to make a failing test pass. Pick whichever fits — they are not ranked, and mixing them across a session is normal.

- **Fake It.** Return a hardcoded literal that satisfies the test (`return 300`). This is not a cop-out — it's the fastest way to get a green bar when you're unsure of the real logic, and it defers design decisions until a second test forces generalization. Always intend to remove the fake as soon as a second, differently-valued test arrives.
- **Obvious Implementation.** If the real implementation is short and you're confident, just write it. Don't perform Fake It theater for something genuinely trivial. If a supposedly-obvious implementation causes an unexpected red bar, that's useful information — drop back to Fake It and smaller steps.
- **Triangulate.** When neither of the above feels safe (the general rule isn't clear yet), add a *second* test with different concrete inputs. Two data points are what force a hardcoded fake into a real, general rule. Use this when you notice you're guessing at the abstraction rather than seeing it.

## Refactoring: only on green

Never refactor with a red bar showing. Refactor in small steps, re-running tests after each one — not as one big cleanup at the end of a session. Typical refactors after a green bar:

- Remove the duplication between the test's expected value and the code that produces it (this is often where the *real* logic gets written, replacing a fake).
- Remove duplication between two now-similar code paths (extract a method, pull up a shared type, introduce a parameter).
- Rename for clarity now that the shape of the solution is visible — names chosen before the code existed are often wrong.
- Simplify conditionals or control flow that only made sense as a stepping stone.

If a refactor breaks a test, that's expected feedback, not a problem — fix the refactor (not the test) and rerun, or back it out and try a smaller step.

## The escape hatch

Strict red-green-refactor is the default whenever Claude is asked to implement or change *behavior*. It is overkill for:

- Pure configuration, wiring, or glue code with no branching logic to get wrong
- Genuine throwaway exploration/spikes, where the user has said they want to try something quickly and will rewrite it properly afterward
- Environments with no test runner available and no reasonable way to add one for the task at hand
- The user explicitly says to skip it ("just write it," "don't bother with tests for this")

When taking the escape hatch, say so in one line ("skipping the test-first cycle here since this is pure config") rather than silently dropping the discipline — the user should know which mode they're getting. If partway through a "quick" task real branching logic shows up, say so and offer to switch into the full cycle for that part.

**Concrete signal that "glue" has quietly become "logic":** you're about to write a conditional, a loop body with more than one branch, or any step that reconciles, combines, or transforms data from more than one source (merging, matching by key, deduplicating, reformatting between shapes). None of those are glue, even inside a task that started as "just write a quick script" — they're exactly the kind of code that can run to completion, exit 0, and still produce silently wrong output, which is worse than crashing because nothing draws attention to the bug. That silent-wrongness, not just "did it crash," is the actual risk the strict cycle defends against — so it's also the test to apply when deciding whether a step still counts as glue.

A second, independent check for anything built in escape-hatch mode: running it and seeing no error is not the same as checking it's *right*. Actually look at the output values, not just the exit code, before calling a quick script done — especially for anything that transforms, merges, or reformats data, where wrong output looks exactly like right output unless you check the actual values.

If it's genuinely unclear which mode fits, default to the strict cycle — it's easier to relax discipline on request than to retrofit tests onto code that already exists.

## Running tests for real

Detect the project's existing test framework and convention before inventing a new one — check for an existing test directory, config file (`pytest.ini`, `jest.config.js`, `pom.xml`, `Cargo.toml`, `go.mod`, etc.), or existing test files, and match their style. See `references/test-runners.md` for framework-specific commands and conventions across common ecosystems (Python, JS/TS, Java, Go, Rust, Ruby).

For every red step and every green step, actually invoke the test runner via bash and read its real output. Show the user the relevant lines (test name + failure or pass), not a paraphrase. If a test fails for a reason unrelated to the behavior being built (import error, typo, environment issue), fix that first and rerun — don't count it as the intended red bar.

## Communicating the cycle to the user

Keep the running commentary short and structural, not a lecture on TDD theory. A good rhythm looks like:

```
Test: parseDuration("5m") == 300
Red — no parseDuration function exists yet. [ran: pytest -k parseDuration, shows failure]
Green — added minimal parseDuration returning a hardcoded 300. [ran: pytest -k parseDuration, passes]
Test: parseDuration("1h") == 3600
Red — hardcoded value fails this input. [ran, fails as expected]
Green — replaced fake with real parsing (split on unit, multiply). [ran, both pass]
Refactor — extracted UNIT_SECONDS map instead of if/elif chain. [ran full suite, still green]
```

Don't narrate every internal deliberation — show the test, the result, and a one-line rationale for the code change. Let the transcript speak for the discipline rather than explaining the discipline itself, unless the user asks.

## Anti-patterns to catch (in yourself and in existing code under review)

- **Writing several tests before making any of them pass.** Defeats the point — go back to one red bar at a time. Concretely: after adding a test function, the very next tool call should run the suite, before any other test function gets written. If the last thing written was a test and the next thing about to be written is *another* test, stop and run first.
- **Writing more production code than the current test demands.** Handling a case no test has asked for yet is scope creep, even when "obviously" needed — write the test for it first, even if trivially.
- **Skipping the refactor step because the code "works."** Working and well-designed are different claims; duplication left in place now is a larger refactor later.
- **Testing implementation details instead of behavior** (e.g., asserting a private helper was called, rather than asserting the observable output) — makes tests brittle to refactoring, which defeats their purpose as a safety net.
- **Treating a failing test as something to silence** (deleting it, loosening the assertion, adding an unjustified skip) rather than as signal to fix the code or reconsider the test.

For the fuller catalog of named patterns this skill draws on (Test List, Child Test, Evident Data, One to Many, and the xUnit-framework patterns), see `references/patterns.md` — read it if you want the vocabulary for explaining a design choice, but the SKILL.md sections above are sufficient to run the cycle itself.

## Worked miniature example

A user asks: "TDD a function that converts Roman numerals to integers."

```
Test list: "I" -> 1, "IV" -> 4, "IX" -> 9, "XL" -> 40, "MCMXCIV" -> 1994, invalid char -> error

Test: romanToInt("I") == 1
Red: function doesn't exist. [run, confirm failure]
Green: Fake It — return 1 unconditionally. [run, passes]

Test: romanToInt("IV") == 4
Red: fake returns 1, expected 4. [run, confirm failure]
Green: Triangulate — build a symbol-value map and sum values, subtracting when a smaller
       symbol precedes a larger one. [run, both tests pass]

Test: romanToInt("IX") == 9, romanToInt("XL") == 40
Red, green (Obvious Implementation now — the subtractive rule is clear). [run, all pass]

Refactor: extract SYMBOL_VALUES map to a constant; rename loop variable for clarity. [run, all green]

Test: romanToInt("MCMXCIV") == 1994
Green immediately — existing logic already generalizes. [run, passes]

Test: romanToInt("IIX") -> error (invalid pattern)
Red: no validation exists yet.
Green: add validation for repeated-subtraction patterns. [run, all pass]
```

Note the shape: fake first, a second data point forces the real rule, obvious implementation once the rule is clear, refactor once green, and the test list drives what comes next rather than trying to design the whole function up front.
