# Mockoon Conventions

Manual test packs use Mockoon exclusively for mocking downstream dependencies. This reference
defines the conventions for route management, manual-flip workflow, latency injection, and
verifying outbound requests.

---

## Route Table Format (README §6)

Every manual test pack README includes a mock table listing all mocked routes:

```markdown
| Route | Default (status) | Other responses |
|---|---|---|
| `POST /api/v1/tokens` | 200 Success | 401 Unauthorized, 500 Server Error |
| `POST /api/v4/emails/templated-send` | 200 Success | 400 Bad Request, 500 Server Error |
| `GET /v1/customer/details/:cifNumber` | 200 Thabo Nkosi | 404 Not Found, 500 Server Error |
```

---

## Core Rules

1. **Exactly one `default: true` per route** — this is the response Mockoon serves when no
   manual flip is active. Never add a second default.
2. **Additive only** — when adding mock responses for new scenarios, add new named responses to
   existing routes. Never rename, remove, or change the default response of an existing route.
3. **Named responses** — every non-default response must have a descriptive `label` (e.g.,
   "404 Customer Not Found", "500 Server Error", "200-with-null-email").

---

## Manual-Flip Workflow

Mockoon's UI allows switching which response is active for a route. The workflow:

### Before a Non-Default Scenario

1. Open Mockoon UI → find the relevant route
2. Click the response tab for the desired non-default response (e.g., "500 Server Error")
3. Set it as the active response (right-click → "Set as default" or drag to top)
4. Run the scenario

### After the Scenario

5. **Immediately flip back** to the original default response
6. Verify the flip-back — send a quick happy-path request to confirm

### Why This Matters

Leaving a route flipped breaks the *next* scenario, not just the current one. This is the
most common source of false failures in manual test runs.

### Scenario File Phrasing

In scenario files, preconditions and cleanup reference the flip like this:

```markdown
## Preconditions
- Mockoon: flip `POST /api/v4/emails/templated-send` to `500 Server Error`

## Cleanup / Reset
- Mockoon: flip `POST /api/v4/emails/templated-send` back to `200 Success` (default)
```

---

## Mock State Matrix

When scenarios require multiple mocks in non-default states simultaneously, include a compact
matrix in the README:

```markdown
## Mock State Matrix (Multi-Mock Scenarios)

| Scenario | Customer Service | Email API | Document Service |
|---|---|---|---|
| 04 - Customer 404, email succeeds | 404 Not Found | default | default |
| 05 - Customer AND attachment fail | 404 Not Found | default | 500 Server Error |
| 06 - Timeout on email send | default | *latency: 35s* | default |
```

This makes multi-mock preconditions scannable at a glance rather than requiring the tester
to open each scenario file to discover the required mock states.

---

## Latency Injection (Timeout/Circuit-Breaker Testing)

Mockoon supports per-response latency (delay before responding). Use this to simulate
timeouts and trigger circuit-breaker behavior.

### When to Use

- Testing timeout handling: set Mockoon delay **greater than** the service's configured
  `timeout-ms` for that downstream call
- Testing circuit-breaker opening: set delay to trigger repeated timeouts

### Configuring in Mockoon UI

1. Select the route → select the response
2. In the response settings, set "Latency" (milliseconds)
3. Note: this affects only that specific response label, not the whole route

### Configuring in `mockoon-env.json`

Each response object has a `latency` field (in milliseconds):

```json
{
  "uuid": "...",
  "statusCode": 200,
  "label": "200 Success - Slow (35s)",
  "latency": 35000,
  "body": "...",
  "default": false
}
```

### Scenario File Phrasing

```markdown
## Preconditions
- Mockoon: flip `POST /api/v4/emails/templated-send` to `200 Success - Slow (35s)`
  (latency 35000ms > service timeout of 30000ms — will trigger timeout)
```

---

## Verifying Outbound Requests (Mockoon Transaction Log)

For pass-through/proxy services, the key verification is: *what did the service send to the
mock?* Mockoon's **Environment Logs** tab records every inbound request.

### How to Check

1. Open Mockoon UI → click "Environment Logs" (clock icon in top bar)
2. Find the request matching your scenario's timestamp/path
3. Inspect: method, path, headers, body

### What to Assert in Scenario Files

```markdown
### HTTP Response Verification
...
Expected outbound call to mock:
- Method + path: `POST /api/v4/emails/templated-send`
- Headers: `x-correlation-id: <FIXED_ID>`, `Authorization: Bearer <token>`
- Body contains: `"templateId": 42`, `"toEmailAddresses": ["customer@example.com"]`
Verify via: Mockoon Environment Logs tab
```

### Header Transformation Verification

If the service transforms headers before forwarding (e.g., renames `correlation-id` →
`x-correlation-id`), the Mockoon transaction log is where you verify the transformation
happened correctly.

---

## Adding a New Named Response to an Existing Route

Minimum JSON to add a new response in `mockoon-env.json` (insert into the route's
`responses` array):

```json
{
  "uuid": "<generate-fresh-uuid>",
  "statusCode": 500,
  "label": "500 Server Error",
  "latency": 0,
  "headers": [
    { "key": "Content-Type", "value": "application/json" }
  ],
  "body": "{\n  \"error\": \"Internal Server Error\",\n  \"message\": \"Simulated failure\"\n}",
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

**Critical**: `"default": false` — never set a new response as default.

---

## Adding an Entirely New Route

When the target endpoint isn't mocked at all yet, add a new route object to the `routes`
array in `mockoon-env.json`:

```json
{
  "uuid": "<generate-fresh-uuid>",
  "method": "post",
  "endpoint": "/api/v2/new-endpoint",
  "documentation": "Description of what this mocks",
  "responses": [
    {
      "uuid": "<generate-fresh-uuid>",
      "statusCode": 200,
      "label": "200 Success",
      "latency": 0,
      "headers": [
        { "key": "Content-Type", "value": "application/json" }
      ],
      "body": "<response body JSON>",
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

---

## Port Conventions

| What | Convention |
|---|---|
| Service under test | Runs on its configured port (e.g., 8080, 8087) |
| Mockoon instance | Runs on a separate port (e.g., 3009, 3010) |
| Service config | Points downstream base-urls at the Mockoon port |

The service's `application-docker.yml` (or `application-local.yml`) should have its
`rest.api.<downstream>.base-url` pointing at the Mockoon host:port.
