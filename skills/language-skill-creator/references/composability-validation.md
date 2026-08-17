# Composability Validation

Use this reference to check whether a generated language standards skill can serve as a clean base for framework and ecosystem overlays.

## Validation Questions

Answer these before finalizing the skill:

- Can a framework skill add framework conventions without contradicting the base language rules?
- Does the language skill avoid mandating a build tool unless that is part of the target scope?
- Does it avoid mandating a testing framework unless the user explicitly included one?
- Does it avoid persistence, web, messaging, cloud, and deployment details?
- Are all MUST and NEVER rules truly language-level correctness, safety, or strong idiom rules?
- Are style preferences either omitted, weakened, or listed as non-standards?
- Does the skill preserve repository conventions over generic advice?
- Does it tell the agent not to modernize unrelated code?
- Does it leave clear space for child skills such as `<language>-<framework>-standards`?

## Overlay Examples

Valid compositions should look like:

```text
java-21-standards
    +
java-21-springboot-standards
```

```text
typescript-standards
    +
typescript-angular-standards
```

```text
csharp-standards
    +
csharp-aspnetcore-standards
```

## Conflict Signals

Revise the base language skill if you see these problems:

- It tells every project to use one architecture.
- It encodes framework lifecycle behavior as language guidance.
- It mandates a formatter, test framework, dependency injector, ORM, or web framework.
- It turns contextual techniques into universal MUST rules.
- It makes child framework skills repeat or fight base language rules.
- It encourages agents to refactor broadly when asked for a narrow change.
- It lacks a non-standards section.

## Boundary Rule

When unsure, keep the base language skill narrower and let overlay skills add ecosystem detail. A weaker, composable base rule is better than a strong rule that blocks legitimate framework guidance.
