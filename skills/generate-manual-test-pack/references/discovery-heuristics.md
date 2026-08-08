# Discovery Heuristics

Systematic algorithm for finding manual test scenarios from code analysis. Use during Step 3
(Enumerate Scenarios) to ensure thorough, consistent coverage rather than relying on intuition.

---

## Overview

Scan the target service's source code in this order. Each heuristic produces zero or more
scenarios. Skip any heuristic that doesn't apply to the scope.

---

## 1. Validation Failures

**Where to look:**
- `@NotBlank`, `@NotNull`, `@NotEmpty`, `@Valid`, `@Validated` annotations on DTOs/parameters
- `if (isBlank(...))`, `StringUtils.isBlank(...)`, `Objects.requireNonNull(...)` in service code
- `@Pattern`, `@Size`, `@Min`, `@Max`, `@Email` bean validation annotations
- Custom validators (`implements ConstraintValidator<...>`)
- Controller `@RequestHeader(required = true)` annotations
- Header-extraction utility methods that throw on missing/blank values
- Interceptors/filters that validate headers before the controller is reached

**Scenario generation rule:**
- One scenario per distinct validation check that produces a user-observable error
- For required headers: test both **missing** (omit entirely) and **blank** (send empty string)
  if the code distinguishes between the two cases
- Group these in the endpoint's folder (or `_cross-cutting/` if they apply to all endpoints)

**Naming convention:** `NN-missing-<field>.md`, `NN-blank-<field>.md`, `NN-invalid-<field>.md`

---

## 2. Required Headers

**Where to look:**
- `@RequestHeader` annotations on controller method parameters
- Interceptors (`HandlerInterceptor.preHandle`) that extract/validate headers
- Filter classes (`OncePerRequestFilter`) that check headers
- Utility methods like `extractHeader(request, "Header-Name")`
- Service-level code that reads headers from `HttpServletRequest` or `@RequestHeader`

**Scenario generation rule:**
- One scenario per required header (omit it entirely → expect 400)
- One scenario per required header (send blank → expect 400), if code distinguishes
- Place in `_cross-cutting/` if the same headers apply to all endpoints in scope

---

## 3. Downstream Failures

**Where to look:**
- `RestClient` / `WebClient` / `RestTemplate` calls in client classes
- Error handlers: `.onStatus(...)`, `ResponseErrorHandler`, try/catch blocks
- `@Retry`, `@CircuitBreaker` annotations on client methods
- Mockoon routes in `mockoon-env.json` — each non-default response represents a testable
  failure mode

**Scenario generation rule:**
- One scenario per distinct HTTP status the downstream can return:
  - **4xx** (400 Bad Request, 401 Unauthorized, 403 Forbidden, 404 Not Found)
  - **5xx** (500 Internal Server Error, 502, 503)
  - **Timeout** (via Mockoon latency injection)
- Only include statuses that the service's error handler differentiates — if the code treats
  all 4xx the same way, one 4xx scenario suffices
- For each, document: what Mockoon response to flip to, what the service returns to the caller

---

## 4. Business Logic Branches

**Where to look:**
- `if/else` and `switch` statements in service classes
- Enum dispatch (`switch(channel)`, `switch(status)`)
- Template resolution logic (different templates produce different outcomes)
- Format rules, transformation logic, conditional enrichment

**Scenario generation rule:**
- One scenario per meaningful business branch (a branch that produces a different observable
  outcome — different status, different response field, different log message)
- Skip branches that only affect internal state with no observable difference
- Flag **surprising** branches (where the outcome is counterintuitive) with
  `⚠️ Surprising:` annotation

---

## 5. Resilience Patterns

**Where to look:**
- `@Retry` annotations — `maxAttempts`, `backoff`, `retryOn`
- `@CircuitBreaker` annotations — `failureRateThreshold`, `waitDurationInOpenState`
- Outbox poll configuration — `poll-interval`, `max-attempts`, `backoff-base-ms`,
  `backoff-cap-ms`
- Timeout configuration — `timeout-ms` per downstream client
- `resilience4j` YAML config sections

**Scenario generation rule:**
- One scenario per resilience mechanism exercised:
  - Retry: downstream fails once then succeeds → request eventually completes
  - Circuit breaker open: downstream fails enough times → breaker opens, request paused/failed
  - Max attempts exhausted: downstream fails persistently → terminal failure
  - Timeout: downstream is slow → service times out
- Mark these `⚠️ Advanced/optional:` with a note about wall-clock cost
- Place in `_resilience/` folder (or `_outbox-resilience/` if outbox-specific)

---

## 6. Idempotency

**Where to look:**
- `UNIQUE` constraints in DB schema (especially on `correlation_id`)
- Idempotency service/checker classes (`IdempotencyService`, `DuplicateChecker`)
- `INSERT ... ON CONFLICT` patterns
- Logic that checks existing state before processing

**Scenario generation rule:**
- **Skip terminal duplicate**: replay a completed request → no-op (zero new rows/events)
- **Resume from partial**: replay a request that was partially processed (e.g., enrichment
  failed) → processing resumes from where it left off
- Both scenarios require a `Depends-on:` referencing the original happy-path scenario
- Place in `_cross-cutting/` folder

---

## 7. Surprising/Edge-Case Behavior

**Where to look:**
- Code comments containing `TODO`, `FIXME`, `HACK`, `NOTE`, `WORKAROUND`
- Error handling that silently swallows exceptions
- Conditional logic where the "else" branch produces a counterintuitive outcome
- Format rules that fail at runtime (e.g., non-numeric value passed to `CURRENCY_2DP`)
- Null propagation paths (null value flows through without validation)

**Scenario generation rule:**
- One scenario per surprising behavior discovered during code analysis
- Pre-annotate with `⚠️ Surprising:` in the scenario metadata
- Explain in the Description section why the outcome is counterintuitive
- These are the highest-value scenarios — they document discovered bugs or design decisions
  that would confuse future maintainers

---

## Scope Boundary Detection

When determining what's in scope for a given test pack:

- **Single endpoint**: all validation, downstream failure, and business-logic scenarios for that
  endpoint's call path
- **Multiple endpoints sharing a downstream**: include cross-cutting downstream failure
  scenarios that affect all of them
- **Kafka consumer**: the entire flow from message receipt to final state (request log, enrichment,
  dispatch, outcome event)
- **Feature/enhancement**: only the paths touched by the change — use git diff or the story
  description to narrow scope

**Heuristic**: if a controller has N endpoints but only M share a downstream dependency,
those M form a natural sub-scope. If all N share the same flow structure, the controller is
one scope.

---

## Scenario Count Expectations

| Scope breadth | Typical scenario count |
|---|---|
| Single endpoint, no downstream | 5–10 (happy path + validation) |
| Single endpoint with downstream | 10–15 (add downstream failures + resilience) |
| Full Kafka consumer flow (with outbox) | 25–40 (all categories) |
| Enhancement/bugfix (narrow change) | 3–8 (just the affected paths) |

These are guidelines, not targets. Coverage is driven by the heuristics above, not by hitting
a number.
