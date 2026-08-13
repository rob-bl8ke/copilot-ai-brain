---
name: plantuml-diagrams
description: 'Generate PlantUML diagrams from specifications, prose descriptions, or selected text. Use when: creating a sequence diagram, activity diagram, class diagram, component diagram, state diagram, or mindmap; documenting workflows, lifecycles, interactions, or structural designs in PlantUML; drawing architecture diagrams with swimlanes, partitions, packages, or state machines; producing sunny-day, rainy-day, or combined flows; generating a conceptual landscape, knowledge overview, or comparative strategy map; generating a PlantUML script from a spec, notes, or selected code.'
argument-hint: '<type> [scenario: sunny|rainy|both] [grouping: partition|lane] [mode: overview|comparison] [scope: single|trunk|satellite] [title: "..."] <description or attached spec>   types: sequence | activity | class | component | state | mindmap'
---

# PlantUML Diagrams

Single skill for generating any PlantUML diagram type from a specification, prose description, or selected text. Each diagram type has its own reference file with a full inlined example, modeling rules, and construction process.

---

## Diagram Type Selection

| Type | Best fit | Reference |
|------|----------|-----------|
| `sequence` | Message flow between actors and services; runtime interactions; retry and failure paths | [sequence-diagram.md](./references/sequence-diagram.md) |
| `activity` | Workflows with decisions, loops, concurrency, and responsibility partitions or swimlanes | [activity-diagram.md](./references/activity-diagram.md) |
| `class` | Structural design: classes, interfaces, enums, inheritance, composition for a service slice | [class-diagram.md](./references/class-diagram.md) |
| `component` | Runtime wiring: components, provided/required interfaces, and inter-component dependencies | [component-diagram.md](./references/component-diagram.md) |
| `state` | Lifecycles, state machines, status progressions, degradation, recovery, and guards | [state-diagram.md](./references/state-diagram.md) |
| `mindmap` | Conceptual landscapes, knowledge overviews, technology ecosystems, comparative strategy maps | [mindmap-diagram.md](./references/mindmap-diagram.md) |

If the diagram type is ambiguous, ask one short clarifying question before proceeding.

---

## Procedure

1. **Select diagram type** — use the table above to identify the right type from the user's description or attached material.
2. **Load the reference file** for that type (links in the table).
3. **Apply type-specific modeling rules** from the reference file — follow the inlined example style, scenario handling, and construction process described there.
4. **Produce the standard output** — see *Output Format* below.

---

## Output Format

All types output a markdown document. Section names vary by type:

| Section | Types |
|---------|-------|
| `# Diagram Script` | all |
| `# Steps` | sequence, activity, state |
| `# Structural Notes` | class, component |
| `# Structure Notes` | mindmap |
| `# Satellite Maps` | mindmap (trunk scope only) |
| `# Short Assumptions` | all |

---

## Shared Quality Rules

- PlantUML syntax must be structurally valid.
- Highlight failure, exception, degraded, retry, or recovery elements with `#LightPink`.
- Keep notes concise; only add them where they materially clarify intent.
- Keep action, state, and label text short and business-readable.
- Do not invent subsystems, classes, or behaviors not present in the source.
- If the source is too ambiguous to proceed, ask one short clarifying question.
- Prefer explicitly attached or selected source material over assumptions; call out inferences in `# Short Assumptions`.

---

## Extending

To add a new diagram type:

1. Create `references/<new-type>.md` using the same structure as the existing reference files: *When to Use*, *Inlined Reference Example*, *Required Modeling Rules*, *Scenario Handling*, *Diagram Construction Process*, *Output Format Note*.
2. Add one row to the selection table above.
