# HTTP Endpoint Pack — Worked Example

Worked example for an **HTTP-endpoint-scoped** service (pure pass-through/proxy, no DB, no
Kafka). Key difference: **no Database or Kafka verification subsections** — HTTP Response +
Log + Breakpoint are the only surfaces.

---

## README Example

```markdown
# Manual Test Suite — <service-name>

Scenarios for <service-name>'s HTTP endpoints. Each scenario is a pre-filled `.http` + `curl`
request, verified via HTTP response, Mockoon transaction log, structured logs, and breakpoints.

## 1. Prerequisites

- Docker-compose stack up (Mockoon)
- Service running on `local` or `docker` profile
- Mockoon environment imported and started on port `<MOCK_PORT>`

## 2. Running the Service

`mvn spring-boot:run -Dspring-boot.run.profiles=local` — port **<PORT>**.
Downstream mocks on Mockoon port **<MOCK_PORT>**.

## 3. Per-Folder Index

| Folder | Endpoint(s) covered | Notes |
|---|---|---|
| `_cross-cutting/` | All endpoints | Missing headers, auth failures |
| `send-email/` | `POST /api/v1/send-email` | Email dispatch scenarios |
| `send-message/` | `POST /api/v1/send-message` | SMS/message dispatch scenarios |

## 4. Request Conventions (Pre-Filled, No Manual Editing Required)

Fixed across all files: `Channel`: `BB-CREDIT`, `Session-Id`: `a1b2c3d4-e5f6-7890-abcd-ef1234567890`,
`Request-Id`: `f9e8d7c6-b5a4-3210-fedc-ba9876543210`, `User-Ref`: `USER-001`,
`Source-System`: `bb-credit-communications`.
Unique per scenario: `Correlation-Id` (the verification key for logs and mock transaction log).

## 5. Mockoon Manual-Flip Workflow

Mockoon (`http://localhost:<MOCK_PORT>`) — flip before non-default scenarios, **flip back after**.

| Route | Default | Other responses |
|---|---|---|
| `POST /api/v1/tokens` | 200 Success | 401 Bad Credentials |
| `POST /api/v4/emails/templated-send` | 200 Success | 400, 500 Server Error, 200 Slow (35s) |
| `POST /api/v2/Message/SendAsync` | 200 Success | 400, 500 Server Error |

### Mock State Matrix

| Scenario | Token endpoint | Send endpoint |
|---|---|---|
| 03 - Token expired | 401 Bad Credentials | default |
| 04 - Downstream 500 | default | 500 Server Error |
| 05 - Downstream timeout | default | 200 Slow (35s) |

## 6. HTTP Response Verification Cheatsheet

Success: `{ "success": true, "provider_message_id": "<non-empty>", "provider_status": "SENT", "message": "Accepted" }`
Validation (400): `{ "type": "BUSINESS", "code": "MISSING_HEADER", "message": "<header>", "traceId": "<uuid>", "timestamp": "<iso>" }`
Downstream error (502): `{ "success": false, "provider_message_id": null, "provider_status": "FAILED", "message": "<detail>" }`

## 7. Growing This Suite

Create a new numbered file in the matching folder. Provide both `.http` and `curl` formats.
Generate a fresh Correlation-Id UUID at authoring time. Add a matching row to
`TEST-EXECUTION-CHECKLIST.md` with Status ⬜.
```

---

## Scenario Example: Happy Path (HTTP Response + Log + Breakpoint)

```markdown
# 01 — Happy Path: Email Accepted

**Endpoint:** `POST /api/v1/send-email`
**Target outcome:** `200` with `success: true`

## Description
Sunny day: all headers present, valid body, Mockoon on defaults. Proves the full
pass-through flow: token acquisition, header transformation, downstream dispatch,
response normalization.

## Request

### .http format
\```http
POST http://localhost:8080/api/v1/send-email HTTP/1.1
Content-Type: application/json
Correlation-Id: d9fd81d9-afe7-4a5e-ba0f-dffd57c79bb7
Channel: BB-CREDIT
Session-Id: a1b2c3d4-e5f6-7890-abcd-ef1234567890
Request-Id: f9e8d7c6-b5a4-3210-fedc-ba9876543210
User-Ref: USER-001
Source-System: bb-credit-communications

{
  "clientType": 1,
  "templateId": 42,
  "templateBodyParameters": "John|10000.00",
  "templateSubjectParameters": "Your account statement",
  "toEmailAddresses": ["customer@example.com"],
  "fromEmailAddress": "noreply@bank.co.za",
  "ccEmailAddresses": [],
  "bccEmailAddresses": [],
  "fileAttachments": []
}
\```

### curl format
\```bash
curl -X POST http://localhost:8080/api/v1/send-email \
  -H 'Content-Type: application/json' \
  -H 'Correlation-Id: d9fd81d9-afe7-4a5e-ba0f-dffd57c79bb7' \
  -H 'Channel: BB-CREDIT' \
  -H 'Session-Id: a1b2c3d4-e5f6-7890-abcd-ef1234567890' \
  -H 'Request-Id: f9e8d7c6-b5a4-3210-fedc-ba9876543210' \
  -H 'User-Ref: USER-001' \
  -H 'Source-System: bb-credit-communications' \
  -d '{
  "clientType": 1,
  "templateId": 42,
  "templateBodyParameters": "John|10000.00",
  "templateSubjectParameters": "Your account statement",
  "toEmailAddresses": ["customer@example.com"],
  "fromEmailAddress": "noreply@bank.co.za",
  "ccEmailAddresses": [],
  "bccEmailAddresses": [],
  "fileAttachments": []
}'
\```

## Expected Behavior

### HTTP Response Verification
Expect status: `200`
Response body:
\```json
{
  "success": true,
  "provider_message_id": "<non-empty string>",
  "provider_status": "SENT",
  "message": "Accepted"
}
\```

Expected outbound call to mock:
- `POST /api/v4/emails/templated-send`
- Headers: `x-correlation-id: d9fd81d9-afe7-4a5e-ba0f-dffd57c79bb7`, `Authorization: Bearer <token>`
- Body: matches inbound request body (pass-through)
- Verify via: Mockoon Environment Logs tab

### Log Verification
- `INFO`, MDC `correlationId=d9fd81d9-afe7-4a5e-ba0f-dffd57c79bb7`
- Message: `"Email dispatched successfully"`

### VS Code Breakpoint
`<EmailDispatchService>#dispatch` — inspect token acquisition, header transformation
(correlation-id → x-correlation-id), downstream response normalized into ProxyResponse.
```

---

## Scenario Example: Missing Required Header (Validation)

```markdown
# 02 — Missing Correlation-Id Header

**Endpoint:** `POST /api/v1/send-email`
**Target outcome:** `400` with `MISSING_HEADER` error

## Description
Omit the `Correlation-Id` header entirely. Service rejects before any downstream call.

## Request

### .http format
\```http
POST http://localhost:8080/api/v1/send-email HTTP/1.1
Content-Type: application/json
Channel: BB-CREDIT
Session-Id: a1b2c3d4-e5f6-7890-abcd-ef1234567890
Request-Id: f9e8d7c6-b5a4-3210-fedc-ba9876543210
User-Ref: USER-001
Source-System: bb-credit-communications

{
  "clientType": 1,
  "templateId": 42,
  "toEmailAddresses": ["customer@example.com"],
  "fromEmailAddress": "noreply@bank.co.za"
}
\```

### curl format
\```bash
curl -X POST http://localhost:8080/api/v1/send-email \
  -H 'Content-Type: application/json' \
  -H 'Channel: BB-CREDIT' \
  -H 'Session-Id: a1b2c3d4-e5f6-7890-abcd-ef1234567890' \
  -H 'Request-Id: f9e8d7c6-b5a4-3210-fedc-ba9876543210' \
  -H 'User-Ref: USER-001' \
  -H 'Source-System: bb-credit-communications' \
  -d '{ "clientType": 1, "templateId": 42, "toEmailAddresses": ["customer@example.com"], "fromEmailAddress": "noreply@bank.co.za" }'
\```

## Expected Behavior

### HTTP Response Verification
Expect status: `400`
Response body:
\```json
{
  "type": "BUSINESS",
  "code": "MISSING_HEADER",
  "message": "Correlation-Id",
  "traceId": "<UUID>",
  "timestamp": "<ISO-8601>"
}
\```
Expected outbound call to mock: **NONE** — request rejected before downstream dispatch.

### Log Verification
Look for (in service console):
- Level: `WARN`
- Message contains: `"Missing required header: Correlation-Id"`

### VS Code Breakpoint
`<HeaderValidationInterceptor>#preHandle` — inspect that the missing header is detected
and the exception is thrown before the controller method is invoked.
```

---

## Scenario Example: Downstream 500 (Mock Flip)

```markdown
# 04 — Downstream Email API Returns 500

**Endpoint:** `POST /api/v1/send-email`
**Target outcome:** `502` or error response from service

## Preconditions
- Mockoon: flip `POST /api/v4/emails/templated-send` to `500 Server Error`

## Description
Downstream email API returns 500. Service returns an error response indicating failure.

## Request

### .http format
\```http
POST http://localhost:8080/api/v1/send-email HTTP/1.1
Content-Type: application/json
Correlation-Id: 5a88efc3-8aa9-41c3-9976-d9cd74de8f6d
Channel: BB-CREDIT
Session-Id: a1b2c3d4-e5f6-7890-abcd-ef1234567890
Request-Id: f9e8d7c6-b5a4-3210-fedc-ba9876543210
User-Ref: USER-001
Source-System: bb-credit-communications

{ "clientType": 1, "templateId": 42, "toEmailAddresses": ["customer@example.com"], "fromEmailAddress": "noreply@bank.co.za" }
\```

### curl format
\```bash
curl -X POST http://localhost:8080/api/v1/send-email \
  -H 'Content-Type: application/json' \
  -H 'Correlation-Id: 5a88efc3-8aa9-41c3-9976-d9cd74de8f6d' \
  -H 'Channel: BB-CREDIT' -H 'Session-Id: a1b2c3d4-e5f6-7890-abcd-ef1234567890' \
  -H 'Request-Id: f9e8d7c6-b5a4-3210-fedc-ba9876543210' \
  -H 'User-Ref: USER-001' -H 'Source-System: bb-credit-communications' \
  -d '{ "clientType": 1, "templateId": 42, "toEmailAddresses": ["customer@example.com"], "fromEmailAddress": "noreply@bank.co.za" }'
\```

## Expected Behavior

### HTTP Response Verification
Expect status: `502` (or service-specific error status)
Response body:
\```json
{ "success": false, "provider_message_id": null, "provider_status": "FAILED", "message": "<error detail>" }
\```

### Log Verification
- Level: `ERROR`, MDC `correlationId=5a88efc3-8aa9-41c3-9976-d9cd74de8f6d`
- Message contains: `"Downstream email API returned 500"`

### VS Code Breakpoint
`<EmailProviderClient>#sendEmail` — inspect the `RestClientResponseException` caught,
confirm the response mapper normalizes it into the error ProxyResponse.

## Cleanup / Reset
- Mockoon: flip `POST /api/v4/emails/templated-send` back to `200 Success` (default)
```
