# Quality Checklist

Use after generating a manual test pack to verify completeness and correctness.

---

## Output Requirements

Every generated test pack must satisfy these structural requirements:

1. Every scenario file lives under the confirmed output location, in the correct folder
2. `README.md` and `TEST-EXECUTION-CHECKLIST.md` sit at the pack's root
3. No `<PLACEHOLDER>` tokens remain in any generated scenario file — all values are concrete
4. Every "Expected Behavior" section includes only subsections for surfaces the service actually
   has for that scope (no empty/inapplicable DB or Kafka subsections)
5. Any new seed SQL or mock routes are additive, idempotent, and called out in the README
6. Checklist row count matches the number of generated scenario files exactly
7. Fixed non-functional values (timestamps, CIF, IDs not under test) are reused consistently
   across scenario files, per [fixture-conventions.md](./fixture-conventions.md)
8. HTTP endpoint scenarios include both `.http` and `curl` formats
9. HTTP endpoint scenarios for pass-through services include expected outbound mock call
   assertions (what the service forwarded to the mocked downstream)
10. Log verification sections are present for services with structured logging + MDC
11. No Database or Kafka subsections for services that don't have those surfaces

---

## Quality Checklist

Before considering the pack complete, verify each item:

### Structure & Completeness

- [ ] Output location was confirmed with the user, not assumed
- [ ] Every category from [discovery-heuristics.md](./discovery-heuristics.md) that applies to
      the scope has at least one scenario
- [ ] Checklist row count equals the number of scenario `.md` files generated
- [ ] README's per-folder index table and progress counters are accurate
- [ ] Each folder has at least one scenario file

### Fixtures & Reproducibility

- [ ] Every scenario file has concrete, pre-filled values — zero placeholders
- [ ] Fixed non-functional values are consistent across all scenario files
- [ ] Correlation IDs are unique per scenario (except intentional idempotency sharing)
- [ ] HTTP scenarios provide both `.http` and `curl` formats
- [ ] Kafka scenarios provide the full Avro JSON envelope (header + body)

### Verification Surfaces

- [ ] Every "Expected Behavior" section matches the verification surfaces detected during
      architecture discovery (no inapplicable subsections)
- [ ] Database verification queries use the scenario's concrete correlation ID (not a placeholder)
- [ ] Log verification includes the expected MDC field and message substring
- [ ] HTTP Response verification includes status code AND body assertion
- [ ] Pass-through service scenarios include outbound mock call assertion
- [ ] Breakpoint sections name real classes/methods from the source code

### Cross-Referencing & Dependencies

- [ ] Idempotency scenarios that share a fixed identifier cross-reference each other explicitly
- [ ] `Depends-on:` fields are present on any scenario that requires a prior scenario to run
- [ ] Dependent scenarios state the concrete shared ID (reader shouldn't have to look it up)

### Mock & Seed Artifacts

- [ ] Any new seed SQL is idempotent (safe to re-run)
- [ ] Any new Mockoon route response has `"default": false`
- [ ] Existing routes, seed rows, and untouched scenario files were not modified when growing
      an existing pack
- [ ] Mock state matrix is present in README when any scenario requires multiple non-default
      mock states simultaneously
- [ ] Latency-injection scenarios document the service's configured timeout for comparison

### Surprising Behavior

- [ ] Surprising/counterintuitive outcomes are annotated with `⚠️ Surprising:` in the scenario
      file's metadata section
- [ ] The Description section explains WHY the behavior is surprising
- [ ] These are treated as the highest-value findings of the manual testing effort

---

## Common Mistakes

| Mistake | Impact | Fix |
|---|---|---|
| Leaving `{{$guid}}` or `<PLACEHOLDER>` in a fixture | Not copy-paste-ready; tester must generate IDs at send time | Hardcode all values at authoring time |
| Including DB verification for a stateless service | False expectations; tester wastes time querying non-existent tables | Check Step 2 surface classification |
| Forgetting Cleanup/Reset on a mock-flip scenario | Next scenario fails with a confusing error | Always add Cleanup section for non-default mock states |
| Same correlation ID across unrelated scenarios | Verification queries return confusing multi-row results | Fresh correlation ID per scenario (except intentional sharing) |
| Missing `Depends-on:` on idempotency scenario | Tester runs it first and gets wrong result | Always add dependency metadata |
| Omitting `curl` format for HTTP scenarios | Tester must manually convert `.http` to curl | Include both formats |
| Adding a second `"default": true` to a Mockoon route | Mockoon behavior becomes unpredictable | Exactly one default per route |
| Not calling out new mock routes in README | Tester doesn't know to import updated Mockoon config | List every new artifact in README |
