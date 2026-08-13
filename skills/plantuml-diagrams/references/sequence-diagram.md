# Sequence Diagram Reference

## When to Use

- Message flow between external actors, service boundaries, and internal components
- Interactions that benefit from `autonumber`, stereotypes, and `box` groupings
- Flows with retries, conditionals, topics, or async messaging
- Sunny-day, rainy-day, or combined interaction scenarios

---

## Inlined Reference Example

```plantuml
@startuml "Signing - Save Contract"
autonumber

actor "<<BFF>>\nContracting" as bff
boundary "<<Gateway>>\nAPI" as gate1

box "Signing" #LightBlue
  boundary SigningService as sign
  control ValidationService as val
  database "Database" as db
  entity "<<message>>\nFailed" as failed
  entity "<<message>>\nFulfilled" as fulfilled
end box

box "Topics" #LightSteelBlue
  database "<<topic>>\nSigningCompleted" as topic1
  database "<<topic>>\nFulfilled" as topic2
end box

actor "Proxy Service" as proxy

bff -> sign: POST /api/v1/signing/contract
note right of bff
  Body:
  - docId, custId, productId
  - Base64 Encoded document
  ---
  - Headers required?
  - Authentication required?
end note

alt "Save the encoded contract locally"
  note right of sign
    If the retry fails, system does not have a document, and this
    operation can be repeated (idempotent).
    Call should also be quick because the database should be close
    to the service.
  end note
    sign -> val: Validate document and metadata
    sign -> db : Save encoded document\nSet application status to CONTRACT_SAVED_LOCALLY
else #LightPink
  sign -> db : Retry (x) number of times
  sign --> bff: Error 500\nReturn a 500 if retry fails.
end

alt "Deliver the contract to the content-proxy service"
  note right of sign
    If the retry fails, system HAS a document, but this
    operation can still be repeated (idempotent).
    User only needs to know that the call failed...
  end note
  sign -> proxy: POST /api/v2/documents/encoded\n{ encodedFile: yXmBbxt==, document: {...} }
  sign -> bff: OK 200
else #LightPink
  sign --> bff: Error 500\nReturn a 500 if proxy is down or fails.
end

topic1 --> sign: Consume failed CONTRACT_DELIVERED_SUCCESSFULLY event (and retry)

alt "Record that the document was sent to the content-proxy service"
  note right of sign
    If the retry fails, system will be in state CONTRACT_SAVED_LOCALLY
    The contract will have been delivered, but the fact is not recorded.
  end note
  sign -> db: Update status to CONTRACT_DELIVERED_SUCCESSFULLY
else #LightPink
  sign -> sign: Create failed event
  note right of sign
    Notify yourself of the failure
  end note
  sign -> topic1: Send failure event
end

note right of sign
  Notify downstream fulfillment
end note
sign --> topic2: Send fulfilment event

topic1 --> sign: Consume failed CONTRACT_DELIVERED_SUCCESSFULLY event (and retry)

alt "Record that fulfillment has been notified"
  sign -> db: Update status to CONTRACT_DELIVERED_SUCCESSFULLY
else #LightPink
  sign -> sign: Create failed event
  sign -> topic1: Send failure event
end

@enduml
```

---

## Required Modeling Rules

- Start with `@startuml "<title>"` and include `autonumber` near the top.
- Identify external actors, system boundaries, internal services, data stores, topics, and entities.
- Use robustness-style participant types:
  - `actor` — external actors or users
  - `boundary` — APIs, gateways, UIs, facades, or service boundaries
  - `control` — orchestration, business logic, validators, processors, or workflow services
  - `database` — data stores, topics, queues, or repositories as persistent/message stores
  - `entity` — domain objects, documents, payloads, events, or message artifacts when relevant
- Use stereotypes in labels where helpful: `<<BFF>>`, `<<Gateway>>`, `<<topic>>`, `<<message>>`.
- Group major subsystems with `box` blocks where this improves readability.
- Add concise `note right of`, `note left of`, or `note over` blocks where clarification materially helps.
- Use `alt`, `else`, `opt`, `loop`, `par`, and `break` for control flow when the source requires it.
- Render rainy-day `else` branches with `#LightPink`.

---

## Scenario Handling

| Requested | Show |
|-----------|------|
| `sunny` | Happy path only |
| `rainy` | Key failure, retry, timeout, compensation, or recovery paths only |
| `both` | Both sunny and rainy paths |
| Not specified | Context-driven: include both if source describes important failure handling; otherwise default to sunny |

---

## Diagram Construction Process

1. Extract the use case title or synthesize a short title from the source.
2. Identify the initiating actor and the first system boundary crossed.
3. Map the main interaction sequence in business order.
4. Add internal control components, data stores, topics, and entities only where meaningful.
5. Model conditionals, retries, loops, or async steps only when supported or strongly implied.
6. Keep naming concrete and business-readable.
7. Keep the diagram focused on one use case or one coherent interaction.

---

## Output Format Note

Output sections in this order:

```
# Diagram Script
# Steps          ← numbered list matching autonumber sequence
# Short Assumptions
```
