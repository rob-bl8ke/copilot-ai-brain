# Fixture Conventions

Defines how to construct reproducible, copy-paste-ready request fixtures for manual test
scenarios. Covers both Kafka payload and HTTP request formats.

---

## UUID Strategy

### Per-Scenario Fresh UUIDs

Generate fresh UUID v4s for **envelope/infrastructure IDs** that must be unique per message:
- `eventId` / `aggregateId` / `schemaId` / `sourceId` (Kafka envelope)
- `Request-Id` / `Session-Id` (HTTP headers, when not testing header validation)

Use `uuidgen` (macOS/Linux) or any UUID v4 generator at authoring time. Hardcode the result
directly into the scenario file — never use runtime generation like `{{$guid}}`.

### Shared Correlation ID

One fixed UUID v4 serves as the **correlation ID** per scenario. Reuse this same value across:
- `header.correlationId` + `header.causationId` + `body.correlationId` (Kafka)
- `Correlation-Id` header (HTTP)

This is the primary key for all verification queries (SQL, Kafka, logs).

### Idempotency Cross-Referencing

When two scenarios deliberately share a correlation ID (e.g., scenario 09 replays scenario 01's
completed ID):
- State the shared UUID explicitly in both files — don't force the reader to go look it up
- Add a `Depends-on:` field in the dependent scenario's metadata
- Both files cross-reference each other in prose

---

## Fixed Non-Functional Values

Choose one value for each non-functional field and reuse it identically across **every**
scenario file in the pack. Declare them once in the README's §5 (Payload/Request Conventions):

| Field | Convention | Example |
|---|---|---|
| Timestamp | Fixed epoch millis (noon on a memorable date) | `1784116800000` |
| Customer ID / CIF | Fixed, non-real | `12345678` |
| Product code | Fixed, descriptive | `PRODUCT_CODE_1` |
| Account number | Fixed, non-real | `ACC-001-00445` |
| Source system | Fixed | `producers-service` |
| Channel | Fixed | `BB-CREDIT` |
| User-Ref | Fixed | `USER-001` |
| Source-System (HTTP) | Fixed | `bb-credit-communications` |

**Why**: eliminates cognitive overhead when reading scenarios — the reader knows these values
are irrelevant and focuses on what actually varies (template variables, business fields, the
correlation ID that drives verification).

---

## Kafka Payload Structure (Avro JSON Representation)

For Kafka-consumer-scoped packs, the fixture is a JSON representation of the Avro message:

```json
{
  "header": {
    "eventId": "<fresh UUID — unique per scenario>",
    "eventType": "DEFAULT",
    "timestamp": 1784116800000,
    "aggregateType": "DEFAULT",
    "aggregateId": "<fresh UUID — unique per scenario>",
    "correlationId": "<SHARED CORRELATION ID for this scenario>",
    "causationId": "<same as correlationId>",
    "sourceId": "<fresh UUID — unique per scenario>",
    "eventVersion": "1",
    "schemaId": "<fresh UUID — unique per scenario>",
    "tenantId": "ZA",
    "contentType": "application/avro",
    "encoding": "UTF-8",
    "retryCount": "0",
    "metadata": {}
  },
  "body": {
    "correlationId": "<same SHARED CORRELATION ID>",
    "sourceId": "producers-service",
    "<business fields that vary per scenario>": "..."
  }
}
```

**Envelope fields** (header block): change only IDs per scenario; `eventType`, `timestamp`,
`aggregateType`, `tenantId`, `contentType`, `encoding`, `retryCount`, `metadata` stay fixed.

**Body fields**: `correlationId` and `sourceId` stay fixed; business fields vary per scenario.

---

## HTTP Request Structure

For HTTP-endpoint-scoped packs, each scenario provides both `.http` and `curl` formats.

### `.http` Format (VS Code REST Client)

```http
POST http://localhost:<port>/api/v1/<endpoint> HTTP/1.1
Content-Type: application/json
Correlation-Id: <FIXED_CORRELATION_ID>
Channel: BB-CREDIT
Session-Id: <FIXED_SESSION_ID>
Request-Id: <FIXED_REQUEST_ID>
User-Ref: USER-001
Source-System: bb-credit-communications

{
  "<field>": "<value>",
  "<field>": "<value>"
}
```

### `curl` Format

```bash
curl -X POST http://localhost:<port>/api/v1/<endpoint> \
  -H 'Content-Type: application/json' \
  -H 'Correlation-Id: <FIXED_CORRELATION_ID>' \
  -H 'Channel: BB-CREDIT' \
  -H 'Session-Id: <FIXED_SESSION_ID>' \
  -H 'Request-Id: <FIXED_REQUEST_ID>' \
  -H 'User-Ref: USER-001' \
  -H 'Source-System: bb-credit-communications' \
  -d '{
  "<field>": "<value>",
  "<field>": "<value>"
}'
```

### Key Rules

- **All IDs baked in** — no `{{$guid}}` or runtime generation. Every header value is a
  concrete UUID hardcoded at authoring time.
- **Session-Id and Request-Id** — use the same fixed values across all scenarios in the pack
  (they're non-functional). Only vary them if testing header validation.
- **Correlation-Id** — unique per scenario (this is the verification key).
- **For header-validation scenarios**: omit or blank the header being tested; keep all others
  at their normal fixed values.

---

## Reproducibility Guarantee

Because every ID is baked in per-file rather than generated at send time:
- Re-sending the exact same file twice (after a DB clean, if applicable) is always safe
- No external tooling state is required — the file IS the test
- The correlation ID in the file matches the verification query exactly — zero copy-paste
  between scenario and verification

---

## Idempotency Scenario Cross-Reference Pattern

When two scenarios share a correlation ID by design (e.g., "happy path completes" →
"replay is skipped"):

**In the dependent scenario's metadata:**
```markdown
**Depends-on:** `../folder/01-happy-path.md` (uses shared correlationId
`bc1967c2-0353-4e37-a266-e6cb4bfb546a`)
```

**In the preconditions:**
```markdown
## Preconditions
- Requires an existing COMPLETED row. First run `../folder/01-happy-path.md` — it uses the
  fixed correlationId `bc1967c2-0353-4e37-a266-e6cb4bfb546a`, reused verbatim below.
- Confirm the prior run is actually COMPLETED before resending:
  \```sql
  SELECT request_status FROM <table> WHERE correlation_id = '<SHARED_ID>';
  \```
  Expect: `COMPLETED`.
```
