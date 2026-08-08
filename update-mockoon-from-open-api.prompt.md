---
name: update-mockoon-from-open-api
description: Reliably update or create Mockoon endpoints from OpenAPI definitions, ensuring all mock routes, ports, and application profile files stay in sync with docker-compose and the latest API contract. Supports batch updates, destructive change confirmation, and an optional preview of planned changes before applying.
argument-hint: Attach one or more OpenAPI files and specify the endpoints you want to update or create in Mockoon. If not specified, you will be prompted to select from available endpoints.
---


# Prompt: Update Mockoon from OpenAPI

## When to use this prompt
- When you want to update or create Mockoon endpoints from OpenAPI specs.
- When you need to keep Mockoon config, docker-compose, and application profile files in sync.
- When onboarding, updating, or removing API endpoints in your mock environment.

## Instructions

Ensure version compatibility with Mockoon App v9.2.0. You want to avoid this error:
```
The content does not seem to be a valid Mockoon environment.
```


1. **OpenAPI and Endpoint Handling**
  - If the mockoon-env.json file does not exist, create a new one with the minimum valid structure for Mockoon App v9.2.0 at the path specified in the docker-compose.yml for the Mockoon service.
  - If no OpenAPI files are provided, prompt the user to attach them.
  - If no endpoints are specified, list all available endpoints from the OpenAPI files and prompt the user to select which to update/create.
  - For each selected endpoint:
    - Parse the OpenAPI definition for method, path, request/response schema, and required headers.
    - Update or create the corresponding route in mockoon-env.json to match the OpenAPI spec.
    - Prompt the user to confirm removal of endpoints in mockoon-env.json not present in the OpenAPI spec.

2. **Docker Compose Port Sync**
  - Parse docker-compose.yml for the Mockoon service’s external (host) port.
  - Ensure mockoon-env.json’s port matches docker-compose. Update mockoon-env.json if needed.

3. **Application Profile File Sync**
  - Auto-detect all application profile files (e.g., application*.yml).
  - For each updated/created endpoint:
    - Ensure the corresponding base-url and endpoint properties are present and correct.
    - If the endpoint is removed, remove the corresponding properties.
    - If base-url is unknown, set to http://localhost:{mockoon-port}.

4. **.http File Generation**
  - For each updated/created endpoint, update or create a .http file for testing, matching the OpenAPI request/response structure.

5. **Preview/Dry-Run (Optional)**
  - If requested, summarize all planned changes (additions, updates, removals) before applying them, and prompt the user for confirmation.

## Relevant files
- mockoon/mockoon-env.json — update/create/remove endpoints
- docker-compose.yml — source of truth for Mockoon port
- src/main/resources/application-*.yml — update API endpoint configs
- docs/temp/*.http — update/create endpoint test files

## Verification
- Confirm mockoon-env.json endpoints match OpenAPI definitions.
- Confirm mockoon-env.json port matches docker-compose.
- Confirm application profile files are in sync.
- Confirm .http files exist and match OpenAPI.
- Confirm user is prompted for destructive changes and preview (if requested).


## Examples

### Example: Valid Mockoon Environment File Structure (v9.2.0)

The following is the **minimum valid structure** for a `mockoon-env.json` compatible with Mockoon App v9.2.0. Always use this as the base when creating a new environment file. Pay close attention to required fields — missing or incorrect values (especially `lastMigration`, `type`, `bodyType`, `rulesOperator`, and `crudKey`) are the most common cause of the "The content does not seem to be a valid Mockoon environment." error.

```json
{
  "uuid": "<generate-a-new-uuid-v4>",
  "lastMigration": 33,
  "name": "My Service - Mock APIs",
  "port": 3000,
  "hostname": "",
  "endpointPrefix": "",
  "latency": 0,
  "proxyMode": false,
  "proxyHost": "",
  "cors": true,
  "routes": [
    {
      "uuid": "<generate-a-new-uuid-v4>",
      "method": "post",
      "endpoint": "api/v1/example",
      "documentation": "Example endpoint",
      "responses": [
        {
          "uuid": "<generate-a-new-uuid-v4>",
          "statusCode": 200,
          "label": "Success",
          "latency": 0,
          "headers": [
            { "key": "Content-Type", "value": "application/json" }
          ],
          "body": "{\n  \"message\": \"OK\"\n}",
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
        },
        {
          "uuid": "<generate-a-new-uuid-v4>",
          "statusCode": 400,
          "label": "Bad Request",
          "latency": 0,
          "headers": [
            { "key": "Content-Type", "value": "application/json" }
          ],
          "body": "{\n  \"message\": \"Bad Request\"\n}",
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
      ],
      "streamingMode": null,
      "streamingInterval": 0,
      "type": "http",
      "responseMode": null
    }
  ],
  "folders": [],
  "proxyReqHeaders": [
    { "key": "X-Correlation-Id", "value": "" }
  ],
  "proxyResHeaders": [],
  "headers": [
    { "key": "X-Powered-By", "value": "Mockoon" }
  ],
  "data": [],
  "rootChildren": [
    { "type": "route", "uuid": "<must-match-the-route-uuid-above>" }
  ],
  "callbacks": [],
  "proxyRemovePrefix": false,
  "tlsOptions": {
    "enabled": false,
    "type": "CERT",
    "pfxPath": "",
    "certPath": "",
    "keyPath": "",
    "caPath": "",
    "passphrase": ""
  }
}
```

**Critical rules to prevent the "not a valid Mockoon environment" error:**
- `lastMigration` **must be `33`** for Mockoon App v9.2.0 compatibility.
- Every route `uuid` in `routes` **must also appear** in `rootChildren` (or inside a folder's `children`).
- Every route **must have** `"type": "http"` and `"responseMode": null` (or a valid mode string).
- Every response **must have** `"bodyType": "INLINE"` (or `"FILE"` / `"DATABUCKET"`), `"rulesOperator": "OR"`, and `"crudKey": "id"`.
- Exactly **one response per route must have** `"default": true`.
- `"streamingMode": null` and `"streamingInterval": 0` are required on every route.
- All UUID values must be valid UUID v4 strings — never reuse UUIDs across routes or responses.
- `"data"`, `"folders"`, `"callbacks"`, `"proxyResHeaders"` may be empty arrays but **must be present**.

### Example: Application profile endpoint config

Look in the profile files for examples of how to structure the base-url and endpoint properties for each API endpoint. For instance, if you have an endpoint defined in OpenAPI like this:

```yaml
rest:
  api:
    endpoint-name:
      base-url: "https://hostname:port"
      endpoint: "api/v1/segment/segment/{id}"
```

If it's not there, the prompt should add it with the base-url set to http://localhost:{mockoon-port} and the endpoint set to the path defined in OpenAPI. If the endpoint is removed from OpenAPI, it should be removed from the profile files as well.
