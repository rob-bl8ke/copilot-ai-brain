# plantuml-diagrams

Single skill for generating any PlantUML diagram type from a specification, prose description, selected text, or attached source material. Consolidates five standalone diagram prompts into one extensible entry point.

Covers:

- **Sequence** — message flow, robustness stereotypes, autonumber, `box` groupings, retries, `alt`/`else`
- **Activity** — workflows with decisions, loops, concurrency, partitions, and swimlanes
- **Class** — structural design: classes, interfaces, enums, inheritance, composition for a service slice
- **Component** — runtime wiring: components, provided/required interfaces, inter-component dependencies
- **State** — lifecycles, state machines, status progressions, degradation, recovery, and guards

---

## Layout

- [SKILL.md](./SKILL.md) — entry point: diagram type selection table, procedure, shared output format, shared quality rules, extending guide
- [references/sequence-diagram.md](./references/sequence-diagram.md) — sequence: inlined example, modeling rules, scenario handling, construction process
- [references/activity-diagram.md](./references/activity-diagram.md) — activity: inlined example, modeling rules, scenario/grouping handling, construction process
- [references/class-diagram.md](./references/class-diagram.md) — class: inlined example, modeling rules, construction process
- [references/component-diagram.md](./references/component-diagram.md) — component: inlined example, modeling rules, construction process
- [references/state-diagram.md](./references/state-diagram.md) — state: inlined example, modeling rules, scenario handling, construction process

---

## Try It

```
/plantuml-diagrams sequence Create the onboarding flow from the attached spec. Scenario: both.

/plantuml-diagrams activity Generate a claims-submission workflow from the selected text. Grouping: lane. Partitions: customer, API, workflow service, assessor.

/plantuml-diagrams class Model these related classes: DeliveryService, DeliveryClient, DeliveryRepository, DeliveryRecord, DeliveryStatus.

/plantuml-diagrams component Create a focused component diagram for the document delivery slice. Emphasis: interface contracts and runtime wiring.

/plantuml-diagrams state Create a document-processing lifecycle from the attached spec. Scenario: both. Emphasis: failure recovery.
```

---

## Adding a New Diagram Type

1. Create `references/<new-type>.md` following the structure of the existing reference files:
   - *When to Use*
   - *Inlined Reference Example* (full PlantUML script)
   - *Required Modeling Rules*
   - *Scenario Handling* (if applicable)
   - *Diagram Construction Process*
   - *Output Format Note* (section names and any type-specific notes)
2. Add one row to the selection table in [SKILL.md](./SKILL.md).
