---
name: plantuml-component-diagram
description: Create a markdown document containing a focused PlantUML component diagram, structural notes, and short assumptions from a specification, selected text, or a provided set of related components. Use when you need to model the runtime structure, boundaries, and dependencies between components in a service slice rather than class-level internals.
argument-hint: Describe the service slice or bounded area to model and optionally specify the related components, package/boundary names, title, emphasis areas (interfaces, dependencies, provided/required ports, boundary grouping), and whether to infer components from a spec section.
agent: agent
---

# Prompt: Generate Component Diagram

Generate a markdown document containing a focused PlantUML component diagram script, structural notes, and short assumptions from the specification, selected text, attached source material, or a user-provided list of related components.

Before drafting, study the full PlantUML example below and use it as a scripting reference for:
- focused package-scoped component modeling for one service slice
- multiple related packages at the same structural level when the design spans adjacent concerns
- components, interfaces, ports, and concrete implementations
- provided interfaces (`-`), required interfaces (`-(0`), and dependency arrows
- usage (`..>`) and dependency (`-->`) relationships between components
- concise port/interface labels only where they materially clarify design intent
- readable grouping, low-crossing relationship direction, and squarish layout
- notes that explain design intent rather than restating names

Treat the example as a pattern for structure and syntax, not as domain content to copy. Reuse the style, but rename packages, components, interfaces, and notes to match the user's source material.

## Inlined reference example

```plantuml
@startuml "Document Delivery - Component Slice"

left to right direction
skinparam shadowing false
skinparam componentStyle rectangle
skinparam packageStyle rectangle
skinparam linetype ortho

package "application" {

  component DeliveryService {
    interface "IDeliveryService" as IDeliverySvc
    portout "IDeliveryClient" as pDeliveryClient
    portout "IDeliveryRepository" as pDeliveryRepo
    portout "IRetryPolicy" as pRetryPolicy
  }
}

package "integration" {

  component HttpDeliveryClient {
    interface "IDeliveryClient" as IDeliveryClient
  }

  component DeliveryClientConfig {
  }
}

package "persistence" {

  component JpaDeliveryRepository {
    interface "IDeliveryRepository" as IDeliveryRepo
  }
}

package "domain" {

  component RetryPolicyProvider {
    interface "IRetryPolicy" as IRetryPolicy
  }
}

DeliveryService ..> HttpDeliveryClient : uses IDeliveryClient
DeliveryService ..> JpaDeliveryRepository : uses IDeliveryRepository
DeliveryService ..> RetryPolicyProvider : uses IRetryPolicy

HttpDeliveryClient ..> DeliveryClientConfig : configured by

note right of DeliveryService
  Models runtime wiring between components.
  Keep closely related components near each other.
  Prefer package-level grouping and orthogonal lines
  to reduce crossings and improve readability.
end note

@enduml
```

## When to use this prompt
- When you want to model the runtime structure and wiring for one part of a service, feature, or bounded slice
- When you have a list of related components and want a focused component diagram rather than a full codebase map
- When you want to infer components from a specification, feature description, or selected text
- When interface contracts, provided/required ports, and inter-component dependencies matter more than class-level internals

## Source rules
- Prefer source material explicitly attached to chat or selected in the editor.
- If the user provides a list of related components, focus on those components and the minimum supporting interfaces or boundaries needed to make the structure understandable.
- If the user asks to model part of a specification, infer only the components, interfaces, and dependencies reasonably supported by that specification slice.
- If the source is insufficient, infer only what is reasonably supported and call out assumptions briefly in the `# Short Assumptions` section.
- If no usable source material is available, ask the user for the specification, notes, or related components before drafting.

## Required modeling rules
- Output a valid PlantUML component diagram script.
- Start with `@startuml "<title>"`.
- Keep the diagram focused on one service slice, feature area, or cohesive structural boundary.
- Prefer package or namespace grouping when it improves readability.
- When the design spans adjacent concerns, prefer multiple peer-level packages rather than one oversized package.
- Include only the components, interfaces, ports, and boundaries that materially clarify the design.
- Show provided interfaces, required interfaces, usage dependencies, and component-to-component relationships only when they are supported by the source or strongly implied.
- Prefer concise interface or port labels only when they materially clarify responsibility or dependency contracts.
- Avoid turning the diagram into a full source-code dump.
- Favor a squarish, readable layout with few crossing lines.
- Keep closely related components physically near each other.
- Prefer orthogonal lines and simple relationship directions when they improve readability.
- Use notes sparingly to clarify architectural intent, scope, or modeling decisions.
- Keep names concrete and aligned with the source material.

## Diagram construction process
1. Extract the structural slice title or synthesize a short title from the source.
2. Identify the central service or feature boundary being modeled.
3. Determine the key related components, interfaces, ports, clients, repositories, adapters, or external systems.
4. Group those elements into a small number of peer-level packages when package boundaries improve readability.
5. Place closely related components near each other and add the minimum useful relationships needed to explain the structure.
6. Include interface labels or port names only where they make the design materially easier to understand.
7. Add notes only where they clarify design intent, scope, or non-obvious relationships.
8. Keep the diagram focused on one coherent design slice and optimize for clean visual layout.

## Output format
- Output markdown only.
- Structure the response as a markdown document with exactly these sections in this order:
  - `# Diagram Script`
  - `# Structural Notes`
  - `# Short Assumptions`
- In `# Diagram Script`, provide a fenced `plantuml` block containing only the script.
- In `# Structural Notes`, provide a short bullet list summarizing the key structural decisions, relationships, and responsibilities shown in the diagram.
- Keep each structural note short, concrete, and design-focused.
- In `# Short Assumptions`, list only the assumptions or inferred details needed to complete the diagram. If no assumptions were needed, state `None.`
- If the source is too ambiguous to produce a responsible diagram, ask a short clarifying question instead of guessing.

## Quality bar
- Ensure the PlantUML syntax is structurally valid.
- Preserve the focused structural style demonstrated by the inlined example.
- Ensure the `# Structural Notes` section matches the diagram rather than introducing new design facts.
- Prefer clarity over exhaustiveness; do not invent large component models, infrastructure layers, or frameworks that are not supported.
- Keep notes short and useful.
- Favor clean package-level organization, short visual distance between related components, and minimal line crossings.
- Avoid clutter from low-value ports, interfaces, or relationships when a smaller diagram communicates the design better.

## Markdown output template

~~~~markdown
# Diagram Script
```plantuml
@startuml "<title>"
left to right direction
skinparam componentStyle rectangle
skinparam linetype ortho

package "application" {
  component ExampleService
}

package "integration" {
  component ExampleClient {
    interface "IExampleClient" as IExampleClient
  }
}

ExampleService ..> ExampleClient : uses IExampleClient
@enduml
```

# Structural Notes
- {Key component responsibility or boundary decision}
- {Important dependency or interface contract}

# Short Assumptions
- {Only inferred details that were necessary}
~~~~

## Example invocation ideas
- `/generate-component-diagram Create a focused component diagram for the document delivery slice from the attached spec. Emphasis: interface contracts and runtime wiring.`
- `/generate-component-diagram Model these related components: DeliveryService, HttpDeliveryClient, JpaDeliveryRepository, RetryPolicyProvider.`
- `/generate-component-diagram Use the selected specification text to infer the components for the payment authorization feature and keep the diagram focused on provided and required interfaces.`
