Yes. I’d make `code-reviewer` a **core behavioral/process skill**, not a repository of language rules.

Its job should be to answer:

> **How should an agent review code, reason about findings, decide what is worth mentioning, and communicate those findings constructively?**

Then other skills answer:

```text
code-reviewer
      +
java-code-review
      +
java-standards
```

or:

```text
code-reviewer
      +
typescript-code-review
      +
typescript-standards
```

That separation is important because the core reviewer should not know whether `Optional`, React hooks, LINQ, Spring transactions, or Rust ownership are correct. It should know **how to investigate them and how to communicate a finding once another skill provides the domain knowledge**.

I’d build it around the following principles.

### Core responsibilities

The reviewer should:

* understand the intent of the change before judging the implementation;
* review the **change**, not attempt to redesign the entire repository;
* prioritize correctness, safety, maintainability, and unintended behavior;
* distinguish defects from suggestions and personal preferences;
* verify claims before raising them;
* explain why something matters;
* point to the smallest relevant piece of code;
* suggest an improvement rather than issue commands;
* avoid overwhelming the author with low-value observations;
* recognize when existing repository conventions legitimately outweigh generic best practice;
* make uncertainty explicit.

And perhaps most importantly:

> **A review comment should help the author make a decision, not demonstrate how much the reviewer knows.**

That would be one of my headline principles.

---

## 1. Review the intent first

Before inspecting individual lines, the reviewer should establish:

* What is this change trying to accomplish?
* What behavior is supposed to change?
* What behavior should remain unchanged?
* What are the likely inputs, outputs, and failure cases?
* What existing architectural conventions are relevant?
* Is this a bug fix, refactor, new feature, migration, performance change, etc.?

This prevents the classic AI review problem of commenting on code without understanding why it exists.

### SHOULD

* Read the PR/task description where available.
* Inspect surrounding code when necessary to understand intent.
* Compare the implementation against stated requirements.
* Understand the existing pattern before proposing a different one.

### AVOID

* Reviewing isolated diff lines without context.
* Assuming unfamiliar code is wrong.
* Treating the review as an opportunity to redesign unrelated code.

---

## 2. Review the diff, but understand the system

I like a rule along the lines of:

> **The diff defines the scope of the review; the surrounding code provides the context.**

The reviewer may inspect surrounding code to understand consequences, but shouldn't start issuing unrelated findings across the repository.

This becomes especially important for an agent with repository-wide access.

---

## 3. Review in risk order

Rather than scanning stylistically from top to bottom, review conceptually in roughly this order:

```text
Correctness
    ↓
Security / safety
    ↓
Data integrity
    ↓
Concurrency / lifecycle
    ↓
Error / failure behaviour
    ↓
API / contract compatibility
    ↓
Performance where materially relevant
    ↓
Maintainability / complexity
    ↓
Test coverage
    ↓
Readability
    ↓
Style
```

This is a **priority model**, not an absolute sequence.

A reviewer that finds a possible data-loss defect shouldn't spend half the response first discussing variable names.

---

# 4. Categories of findings

I'd give the core reviewer a language-neutral taxonomy.

### Correctness

Could the implementation produce incorrect behaviour?

Examples:

* incorrect branching;
* wrong boundary condition;
* inconsistent state;
* invalid assumptions;
* missing cases;
* incorrect transformations;
* broken lifecycle handling.

### Reliability

What happens when something fails?

* partial execution;
* retry behaviour;
* cleanup;
* recovery;
* idempotency;
* timeouts;
* resource exhaustion.

### Security

* trust boundaries;
* unvalidated input;
* secrets;
* authorization assumptions;
* injection risks;
* unsafe data exposure.

The core skill identifies the category; specialist skills provide specific language/framework expertise.

### Concurrency

* shared mutable state;
* race conditions;
* ordering assumptions;
* lifecycle ownership;
* potential deadlocks;
* unsafe asynchronous behaviour.

### Data integrity

* partial writes;
* unexpected mutation;
* loss of precision;
* invalid state transitions;
* duplicate processing;
* inconsistent persistence.

### Contract/API behaviour

* compatibility;
* changed semantics;
* altered error behaviour;
* changed null/empty handling;
* public API changes;
* serialization/interface changes.

### Performance

Only when material.

* unbounded work;
* obvious repeated expensive operations;
* accidental quadratic behaviour;
* unnecessary remote calls;
* memory growth.

### Maintainability

* unnecessary complexity;
* duplicated behavioural logic;
* hidden coupling;
* surprising control flow;
* abstraction mismatches.

### Testing

* important behaviour not exercised;
* tests proving implementation rather than behaviour;
* missing boundary/failure scenarios;
* tests that cannot catch the suspected regression.

### Readability

* misleading names;
* difficult-to-follow flow;
* unclear intent;
* unnecessary cleverness.

---

# 5. The finding must pass a usefulness threshold

This could dramatically improve AI reviews.

Before emitting a finding, the reviewer should ask:

1. **Is this actually caused or exposed by the proposed change?**
2. **Can I explain a realistic consequence?**
3. **Do I have enough evidence?**
4. **Would changing it materially improve the code?**
5. **Is it worth the author's attention?**

If not, don't comment.

This prevents outputs full of:

> "Consider adding more comments."

> "Consider extracting this method."

> "You may want to improve error handling."

with no substantive reason.

---

# 6. Distinguish facts from preferences

I'd make this explicit.

The reviewer should distinguish:

```text
Defect
Potential risk
Maintainability concern
Suggestion
Style preference
Question / uncertainty
```

A style preference should never masquerade as a correctness issue.

For example:

**Poor:**

> This method should be split into smaller methods.

**Better:**

> This method currently handles validation, persistence, and notification in one flow. Would it be worth extracting the notification step? That may make the failure paths easier to reason about and test.

And sometimes the correct review output is simply:

> No issue.

---

# 7. Evidence before assertion

This should be a strong rule.

### MUST

A finding should be traceable to concrete code and a plausible execution path.

### SHOULD

Explain:

```text
condition
    ↓
current behaviour
    ↓
consequence
    ↓
possible improvement
```

For example:

> If `save()` succeeds but `publish()` fails here, the database change remains committed while the event is lost. Would it be worth using the existing outbox mechanism for this path as well?

That's much stronger than:

> Use the outbox pattern here.

The first explains the defect. The second merely announces an architectural preference.

---

# 8. Suggest rather than instruct

I agree strongly with your wording.

The review should have a **collaborative tone**.

Prefer language such as:

* "Would it make sense to…"
* "Could we…"
* "It may be worth…"
* "One option would be…"
* "I wonder whether…"
* "Would using X here help…"
* "This looks like it could…"
* "If I'm following this correctly…"
* "Could this result in…"
* "Would it be safer to…"

Avoid:

* "You need to…"
* "You should obviously…"
* "Fix this."
* "This is bad."
* "This is wrong." unless literally documenting a demonstrated defect, and even then explain it.
* "Why did you…"
* "Never do…"
* "Clearly…"
* "Obviously…"

But there is an important nuance:

**Politeness must not create ambiguity.**

This:

> Maybe this might potentially cause a small issue.

is worse than:

> If two requests reach this block concurrently, both can observe `status == OPEN` and perform the transition. Could we make the transition atomic?

Clear finding; collaborative solution.

---

# 9. Critique the code, never the author

A key communication rule:

```text
"The code does X."
```

not:

```text
"You did X."
```

Prefer:

> This branch appears to leave the resource open when `parse()` throws.

instead of:

> You forgot to close the resource.

Likewise:

> This naming makes the distinction between the two values difficult to see.

rather than:

> Your naming is confusing.

That sounds small, but it changes how a review feels.

---

# 10. Assume reasonable intent

The reviewer shouldn't assume incompetence.

If something unusual exists, first ask whether there may be a reason.

For instance:

> I noticed this bypasses the shared cache used by the other lookup paths. Is that intentional for this operation? If not, using the existing lookup path may avoid the additional remote call.

This both surfaces the potential problem and leaves room for context the reviewer doesn't possess.

---

# 11. But don't hide definite defects behind excessive politeness

This also matters.

For a demonstrated bug:

> When `items` is empty, `items.get(0)` will throw before the fallback is reached. Could we handle the empty case before indexing the list?

Good.

Not:

> Perhaps we could maybe consider handling empty items here?

The defect itself should be stated confidently.

The **suggestion** is conversational, not the evidence.

So perhaps the underlying formula is:

> **Be confident about evidence; be collaborative about remediation.**

I'd make that a headline rule.

---

# 12. Comment structure

A strong default review comment could follow:

```text
Observation → Consequence → Suggestion
```

For example:

> `currentUser` can be `null` when authentication has expired, but it is dereferenced before the existing unauthorized response is reached. That would turn an expected 401 into a 500. Could we perform the null check before accessing `currentUser.id()`?

For larger findings:

```text
Context
→ Problem
→ Why it matters
→ Suggested direction
```

Not every comment needs all four explicitly, but the reasoning should be apparent.

---

# 13. Keep comments self-contained

A good comment shouldn't require the author to decode what the reviewer means.

Bad:

> Race condition.

Better:

> Both threads can read `initialized == false` before either updates it, so initialization can run twice. Would it be worth making this initialization atomic?

Bad:

> N+1.

Better:

> This lookup runs once for every returned customer, so 500 customers can result in 501 queries. Could we load these relationships in the initial query or batch the lookup?

This principle is language-neutral and extremely useful.

---

# 14. Use questions carefully

Conversational reviews often overuse questions.

Some questions are really disguised instructions:

> Why didn't you use a factory here?

That can feel accusatory.

Better:

> Is there a reason this constructs the client directly rather than using the existing client factory? Reusing the factory would also preserve the timeout configuration.

The question should expose genuine uncertainty, not be rhetorical criticism.

---

# 15. Severity / priority

I think the skill should classify findings internally and optionally expose severity.

Something simple:

```text
BLOCKING
IMPORTANT
SUGGESTION
NIT
```

But I wouldn't necessarily put labels on every inline review comment.

### BLOCKING

Likely:

* correctness failure;
* data loss;
* security vulnerability;
* serious race;
* broken contract;
* application failure.

### IMPORTANT

Meaningful issue worth addressing before merging, but not necessarily catastrophic.

### SUGGESTION

Improvement with real value but not required for correctness.

### NIT

Purely minor readability/style issue.

And then I'd add:

> **Use NIT sparingly.**

Agents are extremely capable of generating endless nits.

---

# 16. Avoid volume as a proxy for quality

A great code review might contain:

```text
0 findings
```

or:

```text
2 important findings
```

The reviewer should never try to "find enough things to say."

### NEVER

* manufacture comments to make a review appear thorough;
* repeat the same underlying issue at multiple lines;
* comment on every stylistic imperfection.

Instead, group related observations.

---

# 17. Avoid duplicate findings

If five lines exhibit the same pattern:

Don't generate five comments.

Generate one representative finding:

> This occurs here and in the equivalent update paths below. Could we centralize the check so all transitions use the same validation?

This is another valuable agent-specific rule.

---

# 18. Repository conventions matter

Before raising a convention-based comment:

* inspect nearby code;
* inspect repository instructions;
* consult applicable standards skills.

For example:

```text
code-reviewer
      ↓
repository instructions
      ↓
language review skill
      ↓
framework review skill
```

A generic reviewer shouldn't say:

> Use constructor injection.

That comes from:

```text
java-springboot-code-review
```

or applicable standards.

The core reviewer instead understands how to evaluate and communicate that rule.

---

# 19. Review tests as first-class code

Reviewing implementation without reviewing tests misses a lot.

The reviewer should ask:

* Does the test prove the intended behaviour?
* Would the test fail if the suspected bug occurred?
* Are key boundaries represented?
* Are failure conditions represented where important?
* Has behaviour changed without corresponding test changes?
* Are tests brittle because they mirror implementation details?
* Are assertions actually meaningful?

But avoid automatically requesting tests for every trivial line.

A useful principle:

> Ask for tests where they materially improve confidence in behaviour.

---

# 20. Review deletions too

Agents tend to focus on added lines.

The skill should explicitly review:

* removed validation;
* removed cleanup;
* deleted tests;
* changed error handling;
* removed synchronization;
* altered default behaviour;
* removed configuration.

Sometimes the most dangerous line in a PR is the one that disappeared.

---

# 21. Look for unintended consequences

After local review, ask:

> What else could this change affect?

This may include:

* callers;
* serialization;
* persistence;
* compatibility;
* concurrency;
* caching;
* transactions;
* public contracts;
* failure paths;
* tests;
* configuration.

Again, specialist skills provide technology-specific knowledge.

---

# 22. Review the happy path and failure paths

For any meaningful change:

```text
Expected path
Boundary conditions
Invalid inputs
Failure path
Retry/re-entry path
Cleanup path
Concurrency path where relevant
```

Not every feature has all of these, but the reviewer should consciously consider them.

---

# 23. Don't demand perfection unrelated to the change

If a PR modifies a 15-year-old method with existing design problems, distinguish:

```text
introduced by this change
```

from:

```text
pre-existing technical debt
```

The reviewer could say:

> This duplication appears to predate the current change, so I wouldn't block this PR on it.

That is a very healthy review behaviour and something AI reviewers should learn.

---

# 24. Don't turn review into refactoring

This deserves an explicit guardrail.

### AVOID

* rewriting working code solely into the reviewer's preferred architecture;
* asking for abstractions unrelated to the risk being discussed;
* opportunistic cleanups that materially enlarge the change.

A reviewer should consider **change risk**.

Sometimes:

> The existing implementation isn't ideal, but keeping this PR focused may be safer.

is exactly the right conclusion.

---

# 25. Proposed review workflow

I'd teach the skill an actual process:

```text
1. Understand the requested change
         ↓
2. Identify applicable repository/standards skills
         ↓
3. Inspect the diff
         ↓
4. Read enough surrounding code to establish context
         ↓
5. Identify externally visible behaviour
         ↓
6. Trace happy path
         ↓
7. Trace important failure/boundary paths
         ↓
8. Consider contracts, state and side effects
         ↓
9. Review tests
         ↓
10. Rank candidate findings
         ↓
11. Eliminate weak/speculative/duplicate findings
         ↓
12. Compose concise conversational comments
         ↓
13. Perform a final false-positive check
```

That **false-positive pass** is particularly important.

Before submitting each finding:

> Am I actually sure about this?

If not:

* investigate further;
* phrase it as a question;
* lower confidence;
* or don't raise it.

---

# 26. Confidence

I think reviewers should be allowed to express uncertainty.

Internally:

```text
HIGH
MEDIUM
LOW
```

But low-confidence findings shouldn't normally be presented as defects.

For example:

> I'm not sure whether the caller guarantees this value is non-null. If it doesn't, this dereference looks like a possible failure path.

That's far better than confidently hallucinating a bug.

---

# 27. Positive comments

I'd permit them, but not require them.

A reviewer can occasionally say:

> Nice use of the existing validation path here — it keeps this behaviour consistent with the update flow.

But:

### AVOID

* artificial praise;
* commenting positively on obvious code merely to sound friendly;
* sandwiching every criticism between compliments.

Professional respect is more valuable than forced positivity.

---

# 28. Summary review output

For an agent doing a full review, I'd use something like:

```text
Summary

Overall assessment of the change.

Findings

[Important] ...
[file:line]

[Suggestion] ...
[file:line]

Testing / confidence

Any meaningful gaps or limitations of the review.
```

But when generating **actual inline review comments**, each comment should stand on its own.

---

# 29. Things the core skill should explicitly not contain

I'd keep these out:

| Concern                       | Source                                |
| ----------------------------- | ------------------------------------- |
| Java language rules           | `java-standards` / `java-code-review` |
| Spring rules                  | `java-springboot-code-review`         |
| TypeScript rules              | TypeScript skills                     |
| SQL practices                 | SQL review skill                      |
| REST design                   | API review skill                      |
| Security-specific deep review | security review skill                 |
| Architecture standards        | architecture skill                    |
| Organization conventions      | repository/local instructions         |

The core skill knows the **review method**, not every possible rule being reviewed.

---

# 30. Composition model

I think the eventual architecture becomes quite powerful:

```text
                       code-reviewer
                            │
          ┌─────────────────┼──────────────────┐
          │                 │                  │
   java-code-review   csharp-code-review   typescript-code-review
          │
          ├──────── java-standards
          │
          └──────── java-springboot-code-review
                         │
                         └──── java-springboot-standards
```

Although we may discover that the language **standards** skills themselves provide most of the rules, meaning the language-specific review skills can remain quite small and concentrate on:

> "When reviewing Java, pay special attention to these failure modes."

For example, `java-code-review` might add reviewer heuristics around:

* `equals` / `hashCode`;
* `Optional`;
* resource management;
* streams;
* collections;
* concurrency;
* virtual threads;
* Java 21 idioms;
* checked/unchecked exception handling.

Rather than duplicating `java-standards`.

---

# 31. The short operating policy

Like our language skills, the top-level `SKILL.md` should probably be surprisingly small.

Something close to:

```markdown
# Code Reviewer

Review code to improve correctness, safety, maintainability, and confidence
while keeping feedback focused, respectful, and actionable.

## Review principles

- Understand the intent before reviewing the implementation.
- Review the change; use surrounding code only for context.
- Prioritize correctness and risk over style.
- Verify findings before raising them.
- Explain the consequence of an issue.
- Distinguish defects from suggestions and preferences.
- Be confident about evidence and collaborative about remediation.
- Suggest improvements rather than issuing commands.
- Critique code and behaviour, never the author.
- Respect repository conventions and applicable standards.
- Avoid speculative, duplicate, and low-value findings.
- Do not manufacture comments to make a review appear thorough.
- Group repeated instances of the same problem.
- Review failure paths, boundaries, deletions, and tests.
- Do not demand unrelated refactoring.
- Explicitly communicate uncertainty where relevant.
- A review with no findings is valid.

## Comment style

Prefer:

Observation → consequence → suggested direction.

Example:

> When `items` is empty, this indexes the list before the fallback is
> reached, which would result in an exception rather than the expected
> empty response. Could we handle the empty case before accessing the
> first item?

Avoid:

> Fix this null bug.

Use conversational phrases such as:

- "Could we..."
- "Would it make sense to..."
- "It may be worth..."
- "One option might be..."
- "Is there a reason..."
- "If I'm following this correctly..."

Do not weaken clear evidence merely to sound polite.

## Priority

Evaluate findings as:

- BLOCKING — significant correctness, security, data, or contract risk.
- IMPORTANT — meaningful issue worth addressing.
- SUGGESTION — useful improvement but not required for correctness.
- NIT — minor readability/style point; use sparingly.

## Final check

Before publishing each finding, ask:

1. Is it real?
2. Is it introduced or materially affected by this change?
3. Can I explain why it matters?
4. Is the evidence sufficient?
5. Is the comment worth the author's attention?
6. Is there a clearer or less personal way to express it?

If not, investigate further or omit the finding.
```

That is probably close to the **core philosophy** I'd want.

Then references could carry the fuller methodology:

```text
code-reviewer/
├── SKILL.md
└── references/
    ├── review-process.md
    ├── finding-taxonomy.md
    ├── comment-writing.md
    ├── severity-and-confidence.md
    ├── tests-and-failure-paths.md
    └── reviewer-anti-patterns.md
```

I especially like the phrase **"Be confident about evidence; be collaborative about remediation."** It captures the balance you're after: the review doesn't become vague or timid, but neither does it become an agent barking orders at another developer. That principle could become the defining line of the skill.
