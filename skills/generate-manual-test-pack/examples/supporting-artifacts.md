# Supporting Artifacts — Worked Examples

When scenario discovery reveals gaps (missing mock responses, missing seed data), generate
the supporting artifact directly. This reference shows the patterns for each artifact type.

---

## 1. Seed SQL

Use when scenario requires reference/config data that doesn't exist in the service's default
seed (Flyway migrations or docker-compose init scripts).

### Pattern: Idempotent Upsert

```sql
-- =====================================================================================
-- Manual-test-only seed data for LOCAL docker-compose Postgres.
-- NOT a Flyway migration — Flyway never sees this file. Run manually, once, against the
-- docker-compose database:
--
--   psql -h localhost -U admin -d <database> -f <path>/seed-data.sql
--
-- Safe to re-run: every statement is an idempotent upsert.
--
-- ID reservation (avoids collision with real Flyway-managed data):
--   1-100       -> production ids (Flyway-managed)
--   -1 to -99  -> automated test fixtures (src/test/resources/)
--   9001-9099  -> reserved for this manual-test fixture set
-- =====================================================================================

INSERT INTO <table> (<columns>)
VALUES ('<value_1>', '<value_2>', '<value_3>'),
       ('<value_4>', '<value_5>', '<value_6>')
ON CONFLICT (<unique_column>) DO UPDATE
    SET <column_1> = EXCLUDED.<column_1>,
        <column_2> = EXCLUDED.<column_2>;
```

### Key Rules

- **Always idempotent** (`ON CONFLICT DO UPDATE`) — safe to re-run without cleaning first
- **ID reservation comment** — document which ID ranges are used where to avoid collisions
- **Header comment** — include the exact `psql` command to run it, and note that it's NOT a
  Flyway migration
- **Verification query** — include a `SELECT` at the bottom (commented or separate) that
  confirms the seed applied correctly

### Verification Query Pattern

```sql
-- Verify seed applied correctly:
SELECT <key_columns> FROM <table> ORDER BY <pk>;
-- Expect: <N> rows with values matching the INSERT above
```

---

## 2. Adding a Named Response to an Existing Mockoon Route

Use when a scenario needs a failure-mode response that the route doesn't have yet.

### Minimum JSON to insert into the route's `responses` array

```json
{
  "uuid": "<generate-fresh-uuid>",
  "statusCode": 500,
  "label": "500 Server Error",
  "latency": 0,
  "headers": [
    { "key": "Content-Type", "value": "application/json" }
  ],
  "body": "{\n  \"error\": \"Internal Server Error\",\n  \"message\": \"Simulated downstream failure for manual testing\"\n}",
  "bodyType": "INLINE",
  "default": false,
  "callbacks": [],
  "filePath": "",
  "databucketID": "",
  "sendFileAsBody": false,
  "rules": [],
  "rulesOperator": "OR",
  "disableTemplating": false,
  "fallbackTo404": false,
  "crudKey": "id"
}
```

### Critical Rules

- `"default": false` — ALWAYS. Never set a new response as default.
- `"label"` — descriptive: `"<status> <description>"` (e.g., `"404 Customer Not Found"`)
- Generate a fresh UUID for the `"uuid"` field (use `uuidgen`)
- Insert into the existing route's `"responses"` array — do not create a duplicate route

### Adding a Latency-Injected Response

For timeout testing, add a response with high latency:

```json
{
  "uuid": "<generate-fresh-uuid>",
  "statusCode": 200,
  "label": "200 Success - Slow (35s timeout trigger)",
  "latency": 35000,
  "headers": [
    { "key": "Content-Type", "value": "application/json" }
  ],
  "body": "<same body as the default 200>",
  "bodyType": "INLINE",
  "default": false,
  "callbacks": [],
  "filePath": "",
  "databucketID": "",
  "sendFileAsBody": false,
  "rules": [],
  "rulesOperator": "OR",
  "disableTemplating": false,
  "fallbackTo404": false,
  "crudKey": "id"
}
```

The `latency` value should exceed the service's configured timeout (check
`rest.api.<downstream>.timeout-ms` in the service's YAML config).

---

## 3. Adding an Entirely New Mockoon Route

Use when the scope calls a downstream endpoint that isn't mocked at all yet.

### Minimum JSON to insert into the `routes` array

```json
{
  "uuid": "<generate-fresh-uuid>",
  "method": "<get|post|put|patch|delete>",
  "endpoint": "/api/v1/<path>",
  "documentation": "<What this route mocks>",
  "responses": [
    {
      "uuid": "<generate-fresh-uuid>",
      "statusCode": 200,
      "label": "200 Success",
      "latency": 0,
      "headers": [
        { "key": "Content-Type", "value": "application/json" }
      ],
      "body": "<realistic success response body>",
      "bodyType": "INLINE",
      "default": true,
      "callbacks": [],
      "filePath": "",
      "databucketID": "",
      "sendFileAsBody": false,
      "rules": [],
      "rulesOperator": "OR",
      "disableTemplating": false,
      "fallbackTo404": false,
      "crudKey": "id"
    }
  ],
  "streamingMode": null,
  "streamingInterval": 0,
  "type": "http",
  "responseMode": null
}
```

### Key Rules

- New route gets exactly ONE response with `"default": true`
- `"endpoint"` must match what the service actually calls (check `rest.api.<name>.send-endpoint`
  or the client class's URL construction)
- `"method"` must match (case-insensitive in Mockoon)
- Response body should be realistic — match the downstream's actual API contract (check swagger
  docs or existing integration tests for the response shape)
- Add failure-mode responses (400, 500) as additional non-default entries

---

## 4. When to Generate vs When to Document

| Situation | Action |
|---|---|
| Mock route exists but missing a failure response | Add the response (Section 2 above) |
| Mock route doesn't exist at all | Add the route (Section 3 above) |
| Seed data exists but missing a needed row | Add to existing seed SQL |
| No seed SQL exists and scenarios need reference data | Create new seed SQL (Section 1 above) |
| Mock response exists but with wrong body shape | **Do NOT modify** — document as a known limitation and create a new named response instead |
| Seed row exists but with wrong values | **Do NOT modify** — add a new row with a different ID |

### Always call out new artifacts in the README

When generating supporting artifacts, add a note to the README:

```markdown
## New Artifacts Generated

- **`seed-data.sql`** — adds 3 template rows (IDs 9001-9003) for scenarios requiring
  attachment configs and SMS channels
- **`mockoon-env.json`** — added `500 Server Error` response to `POST /api/v4/emails/templated-send`
  route; added `200 Success - Slow (35s)` response for timeout testing
```

This ensures the reader knows what changed in shared infrastructure config.
