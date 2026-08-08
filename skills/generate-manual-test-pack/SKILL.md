---
name: generate-manual-test-pack
description: 'Generate a repeatable manual test pack (README + execution checklist + numbered scenario files) for a service endpoint, Kafka consumer, or feature/enhancement, by analyzing the target service''s code, config, and integration points. Produces fully pre-filled request/payload fixtures and Expected Behavior verification steps adapted to whatever the service actually has (DB tables, Kafka topics, or HTTP-response-only for pure proxy services). Use when: building a hand-run manual QA suite for a flow, re-testing a specific enhancement, or growing an existing manual test pack with new scenarios.'
argument-hint: 'Path to target service repo + scope (endpoint(s)/consumer(s)/enhancement) + optional scope folder name'
---

# Generate Manual Test Pack

Generate a durable, hand-run manual test pack for a Spring Boot microservice by analyzing its
source code, configuration, and integration points for a given scope.

## Scope Profiles

| Scope type | Verification surfaces | Example to follow | Fixture format |
|---|---|---|---|
| Kafka consumer (with DB + outbox) | Database + Kafka + Log + Breakpoint | [kafka-consumer-pack.md](./examples/kafka-consumer-pack.md) | Avro JSON payload |
| HTTP endpoint (pure pass-through) | HTTP Response + Log + Breakpoint only | [http-endpoint-pack.md](./examples/http-endpoint-pack.md) | `.http` + `curl` |
| HTTP endpoint (with DB) | Database + HTTP Response + Log + Breakpoint | Both examples | `.http` + `curl` |

## When to Use

- Building a manual QA suite to exercise an endpoint, Kafka consumer, or flow end to end
- Re-testing a specific enhancement or bugfix with a repeatable set of steps
- Growing an existing manual test pack with new scenarios
- Preparing a regression pack ahead of a release

## Not For

- Automated tests (unit/integration/E2E) — those are code, not manual test packs
- Operational runbooks/playbooks — use the `generate-playbooks` skill instead

---

## Workflow

### Step 1: Clarify Scope & Output Location

Before analyzing anything, pin down:

1. **Scope** — the exact endpoint(s), `@KafkaListener` consumer(s), or named
   feature/enhancement. Ask the user if ambiguous.
2. **Scope folder name** — short kebab-case (e.g., `send-email-endpoint`, `http-outbox`).
3. **Output location** — **always ask the user to confirm**, even if obvious. Default
   suggestion: `<notes-repo>/<service-name>/manual-tests/<scope-name>/`
4. If a pack already exists at that location, treat as "growing" it (see Step 6).

### Step 2: Discover Architecture & Verification Surfaces

Scan the target service repo scoped to the flow(s) in Step 1. Identify:

1. **Entry points** — REST controllers (method, path, DTOs) or `@KafkaListener` consumers
2. **Business logic** — services, validators, orchestrators, enrichment steps
3. **Downstream dependencies** — RestClient calls (base URL, endpoints, timeout config)
4. **Database** — JPA entities/repositories, which tables matter for verification
5. **Resilience patterns** — retries, circuit breakers, backoff, idempotency
6. **Caching** — cached state and eviction mechanisms
7. **Mock tooling** — Mockoon routes in `mockoon-env.json`
8. **Existing seed/fixture data** — SQL seeds, reference data

Then classify verification surfaces using the decision table in
[verification-patterns.md](./references/verification-patterns.md). Never include a Database
or Kafka subsection for a service that doesn't have that surface.

### Step 3: Enumerate Scenarios

Use the systematic algorithm in [discovery-heuristics.md](./references/discovery-heuristics.md)
to find scenarios from code. Categories:

1. **Happy path** — one+ sunny-day scenarios per flow variant
2. **Validation failures** — one per validation rule (scan `@NotBlank`, header checks, etc.)
3. **Downstream failures** — one per realistic failure from each downstream (4xx, 5xx, timeout)
4. **Infra/protocol-level** — malformed messages, missing headers, auth failures
5. **Idempotency** — duplicate/replay handling (if applicable)
6. **Resilience** — retry/backoff/circuit-breaker (if applicable)
7. **Surprising behavior** — counterintuitive outcomes discovered during analysis; annotate
   with `⚠️ Surprising:` in the scenario metadata

**Folder grouping:**
- `_cross-cutting/` — infra + idempotency scenarios (if applicable)
- `_resilience/` — retry/backoff/CB scenarios (if applicable)
- One folder per distinct endpoint/flow/template

**Always produce the full scaffold** (README + checklist), even for narrow scopes.

### Step 4: Generate Fixtures With Fixed, Reproducible IDs

Build fully pre-filled, copy-paste-ready fixtures — **zero `<PLACEHOLDER>` tokens**.

Follow the conventions in [fixture-conventions.md](./references/fixture-conventions.md):
- Fresh UUIDs for envelope IDs; shared correlationId per scenario
- Fixed non-functional values reused across all files
- **Kafka scope**: full Avro JSON envelope (header + body)
- **HTTP scope**: both `.http` format AND equivalent `curl` command

Add `Depends-on:` metadata for scenarios that require a prior scenario's state.

### Step 5: Generate Supporting Artifacts

When gaps are found (missing mock responses, missing seed data), generate them directly.
Follow patterns in [supporting-artifacts.md](./examples/supporting-artifacts.md) and
[mockoon-conventions.md](./references/mockoon-conventions.md).

- **Seed SQL** — idempotent upserts (`INSERT ... ON CONFLICT DO UPDATE`)
- **Mockoon routes** — new named responses (never a second `default: true`)

**Always additive**: never change existing defaults, seed rows, or existing files.
Call out every new artifact in the README.

### Step 6: Generate the Test Pack Files

Produce at the confirmed output location:

1. **`README.md`** — sections: Prerequisites, Running the Service, Seeding (if applicable),
   Per-Folder Index, Request/Payload Conventions, Mock Manual-Flip Workflow (if applicable),
   Mock State Matrix (if multi-mock scenarios), Verification Library, Growing This Suite.
   See examples: [kafka-consumer-pack.md](./examples/kafka-consumer-pack.md),
   [http-endpoint-pack.md](./examples/http-endpoint-pack.md).

2. **`TEST-EXECUTION-CHECKLIST.md`** — one row per scenario file with status, title, target
   outcome, key identifier, and dependency column. See
   [checklist-and-growth.md](./examples/checklist-and-growth.md).

3. **One scenario `.md` file per enumerated scenario** — in the appropriate folder.

**Growing an existing pack:** add new files, append checklist rows (⬜), update README index
and progress counts. Don't modify existing files.

### Step 7: Cross-Reference & Self-Check

Verify against [quality-checklist.md](./references/quality-checklist.md).

---

## Scenario File Template (Abbreviated)

```markdown
# <NN> — <Short Title>

**<Template|Endpoint>:** `<identifier>` (<method + path> or <template_id>, `<channel>`)
**Target outcome:** `<status code or enum value>`
**Depends-on:** `<path/to/prior-scenario.md>` (if applicable)
**⚠️ Surprising:** <why> (if applicable)

## Description
<1–3 sentences: what this scenario proves.>

## Preconditions
<Omit if none. Otherwise: mock flips, SQL, cache eviction.>

## Request / Payload
<.http + curl (HTTP scope) OR Avro JSON (Kafka scope). Fully pre-filled.>

## Expected Behavior
<Only applicable subsections. See verification-patterns.md for templates.>

## Cleanup / Reset
<Omit if not needed. Flip mocks back, reset flags.>
```

Full worked examples:
- Kafka: [kafka-consumer-pack.md](./examples/kafka-consumer-pack.md)
- HTTP: [http-endpoint-pack.md](./examples/http-endpoint-pack.md)

---

## Reference Documents

| Document | Purpose |
|---|---|
| [verification-patterns.md](./references/verification-patterns.md) | Templates for each verification surface (DB, Kafka, HTTP, Log, Breakpoint) |
| [mockoon-conventions.md](./references/mockoon-conventions.md) | Route management, manual-flip workflow, latency injection, mock state matrix |
| [fixture-conventions.md](./references/fixture-conventions.md) | UUID strategy, fixed values, `.http` + `curl` format, idempotency cross-refs |
| [discovery-heuristics.md](./references/discovery-heuristics.md) | Systematic algorithm for finding scenarios from code analysis |
| [quality-checklist.md](./references/quality-checklist.md) | Output requirements, quality gate, common mistakes |

## Example Documents

| Document | Purpose |
|---|---|
| [kafka-consumer-pack.md](./examples/kafka-consumer-pack.md) | Worked README + scenarios for Kafka-consumer scope (DB + Kafka + Log) |
| [http-endpoint-pack.md](./examples/http-endpoint-pack.md) | Worked README + scenarios for HTTP-endpoint scope (HTTP Response + Log) |
| [checklist-and-growth.md](./examples/checklist-and-growth.md) | Checklist template, dependency levels, dated variant, growth rules |
| [supporting-artifacts.md](./examples/supporting-artifacts.md) | Seed SQL, Mockoon route addition, new route patterns |
