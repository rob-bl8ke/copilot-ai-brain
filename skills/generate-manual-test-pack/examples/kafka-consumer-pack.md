# Kafka Consumer Pack — Worked Example

A complete worked example of a manual test pack for a **Kafka-consumer-scoped** service
(with database persistence, outbox dispatch, and Kafka outcome events).

---

## README Example

```markdown
# Manual Test Suite — <service-name>

A durable, hand-authored, growable collection of manual test scenarios for exercising
<service-name>'s <consumer-name> Kafka consumer flow end to end. Each scenario is a JSON
representation of an Avro message, fed through your producer tool into the running service,
then verified via DB queries, Kafka (AKHQ), structured logs, and VS Code breakpoints.

## 1. Prerequisites

- Docker-compose stack up: `docker-compose.yml` (Postgres, Kafka, AKHQ, Mockoon)
- Seed script run once (see §3 below)
- Service running on the `docker` Spring profile

## 2. Running the Service

`mvn spring-boot:run -Dspring-boot.run.profiles=docker` — port **<PORT>**.

## 3. Seeding Additional Data

\```bash
psql -h localhost -U admin -d <database> -f <path>/seed-data.sql
\```
Safe to re-run (idempotent upserts). Verify: `SELECT <key_columns> FROM <table> ORDER BY <pk>;`
\```

## 4. Per-Folder Index

| Folder | Flow/Template covered | Notes |
|---|---|---|
| `_cross-cutting/` | Infra-level failures, header issues, idempotency | Not tied to one flow |
| `_resilience/` | Outbox retry/backoff/circuit-breaker | Advanced, wall-clock cost |
| `<flow-a>/` | `<FLOW_A_IDENTIFIER>` | Happy path + validation + downstream |
| `<flow-b>/` | `<FLOW_B_IDENTIFIER>` | Different business logic branch |

## 5. Payload Conventions (Pre-Filled, No Manual Editing Required)

Fixed across all files: `header.timestamp`: `1784116800000`, `body.sourceId`: `"producers-service"`,
`body.customerCif`: `"12345678"`, `body.productCode`: `"PRODUCT_CODE_1"`,
`body.accountNumber`: `"ACC-001-00445"`.

Unique per scenario: `header.eventId`, `header.aggregateId`, `header.sourceId`,
`header.schemaId`, and the shared `correlationId` (used for all verification queries).

## 6. Mockoon Manual-Flip Workflow

Mockoon (`http://localhost:<MOCK_PORT>`) — flip before non-default scenarios, **flip back after**.

| Route | Default | Other responses |
|---|---|---|
| `GET /v1/customer/:id` | 200 Success | 404 Not Found, 500 Server Error |
| `POST /api/v1/send-email` | 200 Success | 400, 500 |
| `GET /api/v1/documents/:id` | 200 Binary | 404, 500 |

## 7. SQL Verification Query Library

\```sql
-- Single-table lookup by correlation_id
SELECT * FROM <request_table> WHERE correlation_id = '<CORRELATION_ID>';

-- Everything joined in one shot
SELECT r.correlation_id, r.request_status, r.failure_reason,
       d.dispatch_status, o.status AS outbox_status, o.attempt_count,
       e.event_type
FROM <request_table> r
LEFT JOIN <dispatch_table> d ON d.<fk> = r.<pk>
LEFT JOIN <outbox_table> o ON o.<fk> = r.<pk>
LEFT JOIN <event_table> e ON e.<fk> = r.<pk>
WHERE r.correlation_id = '<CORRELATION_ID>';
\```

## 8. Growing This Suite

Create a new numbered file in the matching folder, following the scenario template in this
skill's examples. Generate fresh UUIDs at authoring time and hardcode directly. Add a matching
row to `TEST-EXECUTION-CHECKLIST.md` with Status ⬜.
```

---

## Scenario Example: Happy Path (DB + Kafka + Log + Breakpoint)

```markdown
# 01 — Happy Path Completed

**Template:** `<TEMPLATE_IDENTIFIER>` (template_id `<ID>`, `<EMAIL|MESSAGE>`)
**Target outcome:** `COMPLETED`

## Description
Sunny day: all required variables present, Mockoon on defaults, no attachments. Proves the
full flow from consumer receipt through enrichment, dispatch, and outcome event publication.

## Avro Payload (JSON representation)
\```json
{
  "header": {
    "eventId": "84d439f7-59f7-401f-9f13-f2f9644ca5af",
    "eventType": "DEFAULT",
    "timestamp": 1784116800000,
    "aggregateType": "DEFAULT",
    "aggregateId": "b287bb04-482d-4ccf-b10b-80423eb81a41",
    "correlationId": "bc1967c2-0353-4e37-a266-e6cb4bfb546a",
    "causationId": "bc1967c2-0353-4e37-a266-e6cb4bfb546a",
    "sourceId": "3c47dc16-0201-49a1-97e2-7164ed3f3a87",
    "eventVersion": "1",
    "schemaId": "f800c6da-8709-4d72-bffa-b299192e209b",
    "tenantId": "ZA",
    "contentType": "application/avro",
    "encoding": "UTF-8",
    "retryCount": "0",
    "metadata": {}
  },
  "body": {
    "correlationId": "bc1967c2-0353-4e37-a266-e6cb4bfb546a",
    "sourceId": "producers-service",
    "templateIdentifier": "<TEMPLATE_IDENTIFIER>",
    "customerCif": "12345678",
    "productCode": "PRODUCT_CODE_1",
    "accountNumber": "ACC-001-00445",
    "templateVariables": {
      "business_name": "Acme Traders",
      "review_date": "2026-08-01"
    },
    "attachments": []
  }
}
\```

## Expected Behavior

### Database Verification
\```sql
SELECT r.correlation_id, r.request_status, r.failure_reason,
       d.dispatch_status, o.status AS outbox_status, o.attempt_count, e.event_type
FROM <request_table> r
LEFT JOIN <dispatch_table> d ON d.<fk> = r.<pk>
LEFT JOIN <outbox_table> o ON o.<fk> = r.<pk>
LEFT JOIN <event_table> e ON e.<fk> = r.<pk>
WHERE r.correlation_id = 'bc1967c2-0353-4e37-a266-e6cb4bfb546a';
\```
Expect: `request_status = COMPLETED`, `dispatch_status = SENT`, `outbox_status = SENT`,
`failure_reason` is NULL, `event_type = CommunicationSent`.
Timing: immediately after sending shows `DISPATCH_PENDING`; re-run within one poll cycle
(≤5s + jitter) for final state.

### Kafka Verification
Topic: `<env-prefix>.<topic.name>` (AKHQ: http://localhost:9099/ui)
Expect: record with headers `Correlation-Id=bc1967c2-0353-4e37-a266-e6cb4bfb546a`,
`Event-Type=CommunicationSent`, body: `status=Sent`, `failureReason=null`.

### Log Verification
Look for (in service console / `docker logs <container>`):
- Level: `INFO`
- MDC `correlationId=bc1967c2-0353-4e37-a266-e6cb4bfb546a`
- Message contains: `"Successfully dispatched"`

### VS Code Breakpoint
`<EnrichmentService>#enrich` — inspect that enrichment completes successfully and
`mergedVariables` contains the expected template variable values.
```

---

## Scenario Example: Idempotency Cross-Reference

```markdown
# 09 — Idempotency: Skip Terminal Duplicate

**Template:** `<TEMPLATE_IDENTIFIER>` (template_id `<ID>`, `<EMAIL>`)
**Target outcome:** True no-op: zero new rows anywhere, zero new outcome events
**Depends-on:** `../<flow-folder>/01-happy-path-completed.md` (uses shared correlationId
`bc1967c2-0353-4e37-a266-e6cb4bfb546a`)

## Description
Resend the exact correlationId of a request already COMPLETED. The idempotency check
short-circuits before any processing occurs.

## Preconditions
- Requires an existing COMPLETED row. First run `../<flow-folder>/01-happy-path-completed.md`
  — it uses the fixed correlationId `bc1967c2-0353-4e37-a266-e6cb4bfb546a`, reused verbatim
  below.
- Confirm the prior run is actually COMPLETED before resending:
  \```sql
  SELECT request_status FROM <request_table>
  WHERE correlation_id = 'bc1967c2-0353-4e37-a266-e6cb4bfb546a';
  \```
  Expect: `COMPLETED`.

## Avro Payload (JSON representation)
\```json
{
  "header": {
    "eventId": "514a348f-d799-446e-b7cf-dd97f3af73a0",
    "eventType": "DEFAULT",
    "timestamp": 1784116800000,
    "aggregateType": "DEFAULT",
    "aggregateId": "020f0e16-7790-46ed-81c5-fcede4698169",
    "correlationId": "bc1967c2-0353-4e37-a266-e6cb4bfb546a",
    "causationId": "bc1967c2-0353-4e37-a266-e6cb4bfb546a",
    "sourceId": "c0f78492-6568-4c93-9d21-335920fbe41f",
    "eventVersion": "1",
    "schemaId": "7a872fb3-8e6e-49f1-ba87-f614769735bb",
    "tenantId": "ZA",
    "contentType": "application/avro",
    "encoding": "UTF-8",
    "retryCount": "0",
    "metadata": {}
  },
  "body": {
    "correlationId": "bc1967c2-0353-4e37-a266-e6cb4bfb546a",
    "sourceId": "producers-service",
    "templateIdentifier": "<TEMPLATE_IDENTIFIER>",
    "customerCif": "12345678",
    "productCode": "PRODUCT_CODE_1",
    "accountNumber": "ACC-001-00445",
    "templateVariables": {
      "business_name": "Acme Traders",
      "review_date": "2026-08-01"
    },
    "attachments": []
  }
}
\```

## Expected Behavior

### Database Verification
\```sql
SELECT COUNT(*) FROM <request_table>
WHERE correlation_id = 'bc1967c2-0353-4e37-a266-e6cb4bfb546a';
\```
Expect: exactly 1 row (no duplicate insert). `request_status` remains `COMPLETED`.

### Log Verification
Look for (in service console):
- Level: `INFO`
- MDC `correlationId=bc1967c2-0353-4e37-a266-e6cb4bfb546a`
- Message contains: `"Skipping already-terminal correlationId"`

### VS Code Breakpoint
`<IdempotencyService>#check` — inspect that the check returns `SKIP` and no further
processing is invoked.
```

---

## Scenario Example: Surprising Behavior

```markdown
# 03 — CURRENCY_2DP Invalid Value → DISPATCH_FAILED

**Template:** `<TEMPLATE_IDENTIFIER>` (template_id `<ID>`, `EMAIL`)
**Target outcome:** `DISPATCH_FAILED`
**⚠️ Surprising:** validation passes (value is present and non-blank), but the format rule
fails at dispatch time because `"not-a-number"` cannot be formatted as currency.

## Description
Supply a non-numeric value for a field with a `CURRENCY_2DP` format rule. Passes initial
validation but fails during dispatch preparation when the format rule parses it as a number.

## Avro Payload (JSON representation)
\```json
{ "body": { "correlationId": "<FIXED_ID>", "templateVariables": { "amount": "not-a-number" } } }
\```
(Full envelope fields omitted for brevity — same structure as happy-path example above.)

## Expected Behavior

### Database Verification
\```sql
SELECT request_status, failure_reason FROM <request_table>
WHERE correlation_id = '<FIXED_ID>';
\```
Expect: `request_status = DISPATCH_FAILED`, `failure_reason` contains format error detail.

### Log Verification
- Level: `ERROR`, MDC `correlationId=<FIXED_ID>`
- Message contains: `"NumberFormatException"` or `"Failed to format"`

### VS Code Breakpoint
`<FormatService>#applyFormatRules` — inspect the exception thrown when parsing
`"not-a-number"` as a numeric value for `CURRENCY_2DP` formatting.
```
