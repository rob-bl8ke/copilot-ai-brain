# Verification Patterns

When generating a manual test scenario's "Expected Behavior" section, include **only** the
subsections that apply to the target service's scope. This reference defines each verification
surface, its template, and when to include it.

---

## Decision Table: Which Surfaces to Include

| Surface | Include when... |
|---|---|
| Database | Service persists state reachable by a query keyed on correlation_id or similar |
| Kafka | Service publishes outcome/status events to a topic |
| HTTP Response | Always — every scope has some observable response or outcome |
| Log | Always for services with structured logging + MDC correlation-id propagation |
| Breakpoint | Always — name the exact class#method to inspect |

**Pure pass-through services** (no DB, no Kafka producer): HTTP Response + Log + Breakpoint only.
**DB + outbox services**: all five surfaces.
**HTTP endpoint with DB but no Kafka**: Database + HTTP Response + Log + Breakpoint.

---

## 1. Database Verification

Use when the service persists request/outcome state reachable by a correlation_id or trace_id.

### Single-Table Lookup

```sql
SELECT <columns_of_interest>
FROM <table>
WHERE <correlation_column> = '<FIXED_CORRELATION_ID>';
```

### Multi-Join "Everything in One Shot"

```sql
SELECT
    r.<correlation_column>,
    r.<status_column>,
    r.<failure_column>,
    d.<dispatch_status>,
    o.<outbox_status>,
    o.<attempt_count>,
    o.<next_attempt_at>,
    o.<last_error>,
    e.<event_type>
FROM <request_table> r
LEFT JOIN <dispatch_table> d ON d.<fk> = r.<pk>
LEFT JOIN <outbox_table>   o ON o.<fk> = r.<pk>
LEFT JOIN <event_table>    e ON e.<fk> = r.<pk>
WHERE r.<correlation_column> = '<FIXED_CORRELATION_ID>'
ORDER BY e.<pk>;
```

### Row-Count Assertion (Idempotency)

```sql
-- Must stay at exactly 1 row (no duplicate insert)
SELECT COUNT(*) FROM <table> WHERE <correlation_column> = '<FIXED_CORRELATION_ID>';
```

### Template for Scenario File

```markdown
### Database Verification
\```sql
<query with concrete FIXED_CORRELATION_ID filled in>
\```
Expect: `<status_column> = '<VALUE>'`, `<failure_column>` is `NULL`, ...
<Timing note if async: "Re-run within one poll cycle (~5s): status transitions to...">
```

---

## 2. Kafka Verification

Use when the service (or its outbox) publishes an outcome/status event to a topic.

### What to Assert

- **Topic name** (include environment prefix if applicable)
- **Tooling + URL** (e.g., AKHQ: `http://localhost:9099/ui`)
- **Headers**: `Correlation-Id`, `Event-Type`, `Schema-Name`
- **Body fields**: status, failureReason, key business identifiers

### Template for Scenario File

```markdown
### Kafka Verification
Topic: `<environment-prefix>.<topic.name>` (<tooling>: <URL>)
Expect: a `<EventType>` record with headers `Correlation-Id=<FIXED_ID>`,
`Event-Type=<event-type-value>`, body fields: `status=<value>`,
`failureReason=<null or value>`, `<business_field>=<value>`.
```

---

## 3. HTTP Response Verification

**Always include.** For pure pass-through services, this is the primary verification surface.

### What to Assert

1. **Status code** (e.g., 200, 400, 502)
2. **Response body** — exact field values or patterns
3. **Response headers** — if the service sets custom response headers
4. **Outbound mock call** — for pass-through/proxy services: what the service forwarded to
   its mocked downstream (method, path, headers, body). Verify via Mockoon transaction log.

### Template for Scenario File

```markdown
### HTTP Response Verification
Expect status: `<CODE>`
Response body:
\```json
{
  "<field>": "<exact_value_or_pattern>",
  "<field>": "<value>"
}
\```
<If pass-through service:>
Expected outbound call to mock:
- Method + path: `POST <downstream-path>`
- Headers: `<header>: <value>` (note any header renames/transformations)
- Body: `<key fields the service forwarded or transformed>`
Verify via: Mockoon transaction log (Environment Logs tab in UI)
```

### Error Response Template

```markdown
### HTTP Response Verification
Expect status: `400`
Response body:
\```json
{
  "type": "BUSINESS",
  "code": "<ERROR_CODE>",
  "message": "<pattern or exact message>",
  "traceId": "<UUID pattern>",
  "timestamp": "<ISO-8601 pattern>"
}
\```
```

---

## 4. Log Verification

Use for services with structured logging and MDC correlation-id propagation. Often the
**fastest** manual verification — faster than SQL queries for confirming a code path executed.

### What to Assert

- **Log level** (INFO, WARN, ERROR)
- **MDC correlation-id** in the structured log line
- **Message substring** that confirms the expected code path
- **Where to look**: `docker logs <container>` or VS Code Debug Console

### Template for Scenario File

```markdown
### Log Verification
Look for (in service console / `docker logs <container>`):
- Level: `<INFO|WARN|ERROR>`
- MDC `correlationId=<FIXED_ID>`
- Message contains: `"<key substring>"`
<Optional: note if the log line should NOT appear (negative assertion)>
```

### Grep Command Template

```bash
docker logs <container> 2>&1 | grep '<FIXED_CORRELATION_ID>'
```

---

## 5. VS Code Breakpoint

**Always include.** Names the exact code location for interactive debugging.

### Template for Scenario File

```markdown
### VS Code Breakpoint
`<ClassName>#<methodName>` — inspect `<what to look at>` (e.g., variable value,
collection size, exception type). Confirm `<expected observation>`.
```

### Guidelines

- Name the class and method from the actual source code discovered during analysis
- State what to inspect (a variable, a return value, a collection size)
- State what the expected observation is (e.g., "list has 2 elements", "exception is null")
- For async flows, note which thread/executor to watch

---

## Combining Surfaces in a Scenario File

A scenario's "Expected Behavior" section includes subsections in this fixed order (skip any
that don't apply):

1. Database Verification
2. Kafka Verification
3. HTTP Response Verification
4. Log Verification
5. VS Code Breakpoint

Never include empty subsections. If a surface doesn't apply, omit it entirely.
