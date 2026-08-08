# Checklist and Growth — Worked Example

Complete worked examples of the `TEST-EXECUTION-CHECKLIST.md` file, including dependency
levels, the dated execution variant, and growth instructions.

---

## Complete Checklist Template

```markdown
# Manual Test Execution Checklist — <service-name>

Tracks pass/fail as you work through the scenarios in this suite. One row per scenario file;
the key identifier (e.g., `correlationId`) is copied straight from each file so you can paste
it into a verification query or log grep without opening the file first.

**Legend:** ⬜ Not run · ✅ Pass · ❌ Fail · ⚠️ Ambiguous/flaky (needs rerun)

**Before a full run:** <reset instructions — e.g., clean DB + reseed, flip all mocks to default>

**Progress:** 0 / <N> run

---

## `_cross-cutting/` (<count>)

| # | Status | Scenario | Target Outcome | `correlationId` | Depends | Notes |
|---|---|---|---|---|---|---|
| 0001 | ⬜ | [Missing Required Header](_cross-cutting/01-missing-required-header.md) | `400 MISSING_HEADER` | `69ff9214-b618-40ca-9525-c7342cea0963` | — | |
| 0002 | ⬜ | [Blank Required Header](_cross-cutting/02-blank-required-header.md) | `400 MISSING_HEADER` | `ad728010-6118-487a-8e38-4590951276da` | — | |
| 0003 | ⬜ | [Idempotency: Skip Duplicate](_cross-cutting/03-idempotency-skip-duplicate.md) | No-op | `bc1967c2-...` | 0004 | Shared ID with flow-a/01 |

## `<flow-a>/` (<count>)

| # | Status | Scenario | Target Outcome | `correlationId` | Depends | Notes |
|---|---|---|---|---|---|---|
| 0004 | ⬜ | [Happy Path](flow-a/01-happy-path.md) | `COMPLETED` / `200` | `bc1967c2-0353-4e37-a266-e6cb4bfb546a` | — | |
| 0005 | ⬜ | [Missing Business Field](flow-a/02-missing-field.md) | `VALIDATION_FAILED` / `400` | `ae117669-cf13-4ded-908d-51a1770bd19c` | — | |
| 0006 | ⬜ | [Downstream 404](flow-a/03-downstream-404.md) | `CUSTOMER_FAILED` / `404` | `dc9a8cdf-5424-4df9-bc0f-c412c24c2beb` | — | |
| 0007 | ⬜ | [Downstream 500 Then Recovery](flow-a/04-downstream-500-recovery.md) **[ADV]** | `COMPLETED` | `50b71838-2b5a-4006-89ec-a6adc6abd096` | — | Wall-clock cost |

## `_resilience/` (<count>)

| # | Status | Scenario | Target Outcome | `correlationId` | Depends | Notes |
|---|---|---|---|---|---|---|
| 0008 | ⬜ | [Circuit Breaker Open](_resilience/01-circuit-breaker-open.md) **[ADV]** | Paused/failed | `7b93f053-df30-4df7-81b8-5dac2d3b2ed2` | — | Requires repeated failures |
| 0009 | ⬜ | [Max Attempts Exhausted](_resilience/02-max-attempts-exhausted.md) **[ADV]** | `DISPATCH_FAILED` | `cc80008c-07d3-40be-8de5-9559a69a4d49` | — | Long-running |

---

## Run Log

| Date | Run by | Scenarios run | Result summary |
|---|---|---|---|

## Growing This Suite

When you add a new scenario file:
1. Add a matching row in the correct folder section above
2. Copy the fixed `correlationId` from the new file into the row
3. Set Status to ⬜
4. If the new scenario depends on a prior one, fill the `Depends` column with the row number
5. Update the **Progress** counter's total (denominator)
```

---

## Dependency Levels

Group scenarios by execution dependency for efficient test runs:

**Level 1 (no dependencies — run in any order):**
- All validation scenarios
- All happy-path scenarios
- All downstream-failure scenarios (with mock flips)

**Level 2 (requires Level 1 complete):**
- Idempotency "skip duplicate" — requires a completed happy-path run
- Idempotency "resume from partial" — requires a partially-failed run

**Level 3 (requires specific timing/sequencing):**
- Resilience scenarios (circuit breaker, backoff) — require repeated failures over time
- Recovery scenarios — require a failure state followed by a fix

In the checklist, the `Depends` column makes this explicit. Testers can:
1. Run all Level 1 scenarios in parallel or any order
2. Run Level 2 after confirming their dependencies passed
3. Run Level 3 last (these often have `⚠️ Advanced/optional` annotations)

---

## Dated Execution Checklist Variant

For formal QA runs, copy the master checklist to a dated file:

```bash
cp TEST-EXECUTION-CHECKLIST.md 2026-07-16-TEST-EXECUTION-CHECKLIST.md
```

Then fill in results in the dated copy. The master stays clean (all ⬜) as the canonical
template for the next run.

### What to record in the dated copy

- Change `⬜` to `✅`, `❌`, or `⚠️` as you execute
- Add notes in the Notes column for any surprising observations
- Use `❓` (with ⚠️) for "passed but behavior is questionable"
- Update the **Progress** counter as you go
- Fill in the **Run Log** table at the bottom

### Example dated checklist row with findings

```markdown
| 0004 | ✅ | [Happy Path](flow-a/01-happy-path.md) | `COMPLETED` | `bc1967c2-...` | — | Logs correct correlationId |
| 0008 | ✅ ❓ | [Template Inactive](...) | `TEMPLATE_FAILED` | `b39e93de-...` | — | ⚠️ Message should say "inactive" not "not found" |
```

---

## Growing an Existing Pack

When adding scenarios to a pack that already has a checklist:

1. **Add scenario files** to the correct existing folder (or create a new folder)
2. **Append rows** to the checklist in the matching folder section (maintain numbering from
   where the section left off)
3. **Update README** per-folder index table (add new folder or update count)
4. **Update progress counter** (increment the total)
5. **Do NOT modify** existing scenario files or existing checklist rows
6. **Do NOT reset** existing `✅`/`❌` statuses — those represent historical results

If adding a new folder, insert a new section in the checklist between existing sections
(maintain alphabetical or logical ordering).
