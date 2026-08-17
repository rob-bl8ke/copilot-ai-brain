---
name: language-skill-creator
description: Use when creating a reusable language standards skill such as java-21-standards, typescript-standards, csharp-standards, or python-standards. Guides scope definition, standards discovery, rule classification, ecosystem boundaries, non-standards, reference extraction, and composability validation for language-level coding standards. Do not use for framework-only skills except to define their boundary with a base language skill.
---

# Language Skill Creator

Create compact, composable language standards skills that describe how to write good code in a language without absorbing framework, build-tool, persistence, or infrastructure concerns.

## Operating Rules

Keep these rules active while designing the skill:

1. Define the exact language, version, runtime, and standard-library baseline first.
2. Separate language-level standards from framework, build-tool, testing-library, persistence, and infrastructure concerns.
3. Catalogue concepts before writing the final skill.
4. Classify guidance as MUST, SHOULD, CONSIDER, AVOID, or NEVER.
5. Distinguish correctness, safety, and contracts from style preference.
6. Identify legacy idioms and anti-patterns an AI agent should stop generating.
7. Define AI-agent guardrails against overengineering and unrelated modernization.
8. Keep `SKILL.md` compact and policy-oriented.
9. Move detailed standards into reference files.
10. Include a `Non-Standards` section for opinions the language skill refuses to universalize.
11. Design the result so framework and ecosystem skills can layer on top without conflict.

## Core Principle

A language standards skill describes how to write good code in the language. Framework skills describe how to use a framework correctly. Neither should unnecessarily absorb the other's responsibilities.

## Classification Meanings

| Level | Meaning |
|---|---|
| MUST | Required for correctness, safety, language contracts, or strong platform guarantees. |
| SHOULD | Recommended default; deviate when there is a concrete reason. |
| CONSIDER | Useful technique whose value depends heavily on context. |
| AVOID | Usually produces worse code; use only with a specific justification. |
| NEVER | Essentially prohibited in normal application code for this language baseline. |

## Required Questions

Ask or answer these before considering a language skill complete:

1. What exact language/runtime version is targeted?
2. Which features are stable versus preview or experimental?
3. What belongs to the language versus its ecosystem?
4. Which rules are genuine correctness or safety rules?
5. Which rules are merely common style preferences?
6. Which legacy idioms should an AI stop generating?
7. What modern language features should it actively prefer?
8. Where should immutability be preferred?
9. How should errors and resources be handled?
10. What are the language-specific concurrency hazards?
11. Which standard-library APIs should be preferred?
12. What should an agent absolutely not overengineer?
13. What repository conventions should override generic recommendations?
14. What belongs in a child framework or ecosystem skill instead?
15. Can another skill layer on top without contradicting this one?

## Reference Guide

Load only the relevant reference file for the current design step.

| Reference | Use When |
|---|---|
| [Workflow](./references/workflow.md) | Running the full language skill creation process. |
| [Standards Catalogue](./references/standards-catalogue.md) | Discovering and organizing language concepts before drafting guidance. |
| [Output Structure](./references/output-structure.md) | Creating the target skill folder, `SKILL.md`, reference files, and non-standards section. |
| [Composability Validation](./references/composability-validation.md) | Checking that framework and ecosystem skills can layer on top without conflict. |

## Workflow

1. Establish scope and exclusions.
2. Build the standards catalogue.
3. Classify every rule by strength.
4. Remove opinion masquerading as standards.
5. Identify ecosystem boundaries.
6. Extract a compact operating policy for `SKILL.md`.
7. Write reference documents for detailed guidance.
8. Validate composability with likely framework or ecosystem overlays.
