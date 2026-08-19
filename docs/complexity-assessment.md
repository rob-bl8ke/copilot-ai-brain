# Task Complexity Assessment System

Automated system for assessing task complexity and enforcing appropriate review and testing workflows.

## Overview

The complexity assessment system uses pre-hooks to analyze tasks before implementation. If a task exceeds complexity thresholds, it automatically triggers the **auto-review-loop** workflow, which ensures:
- Iterative code review
- Issue detection and fixes
- Automated testing
- Quality gates before completion

## Complexity Scoring

### Score Calculation

Complexity is scored based on multiple signals:

| Signal | Points | Description |
|--------|--------|-------------|
| **Multi-file changes** | +2 | More than 3 files changed |
| **Large change** | +2 | More than 200 lines changed |
| **Multiple packages** | +1 | Changes span multiple packages/modules |
| **New aggregate/entity** | +3 | New DDD aggregate or entity |
| **Event schema change** | +2 | Avro/Protobuf schema changes |
| **New API endpoint** | +2 | New REST controller or endpoint |
| **Database migration** | +2 | Flyway migration files |
| **Kafka integration** | +2 | Kafka consumer/producer changes |
| **Security changes** | +3 | Authentication/authorization code |
| **Saga/distributed tx** | +3 | Saga pattern or distributed transactions |
| **Infrastructure changes** | +2 | Terraform or config changes |
| **Refactoring** | +2 | Code restructuring |
| **Breaking changes** | +2 | Migration or breaking API changes |
| **No tests included** | +2 | Code change without test files |

### Complexity Thresholds

- **Score < 3**: Standard complexity - normal workflow
- **Score 3-4**: Moderate complexity - extra attention recommended
- **Score ≥ 5**: High complexity - **auto-review-loop required**

## Auto-Review-Loop Workflow

When complexity score ≥ 5, the auto-review-loop workflow is triggered:

```
┌─────────────────────────────────────────────────────────────┐
│                    Auto-Review-Loop                         │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
                  ┌──────────────────┐
                  │  1. IMPLEMENT    │
                  │  (general agent) │
                  └──────────────────┘
                            │
                            ▼
                  ┌──────────────────┐
                  │  2. REVIEW       │
                  │  (code-reviewer) │
                  └──────────────────┘
                            │
                ┌───────────┴───────────┐
                │                       │
                ▼                       ▼
         ┌──────────┐           ┌──────────┐
         │  Issues  │           │   LGTM   │
         │  Found?  │           │          │
         └──────────┘           └──────────┘
                │                       │
                │ Yes                   │ No
                ▼                       ▼
      ┌──────────────────┐    ┌──────────────────┐
      │  3. FIX ISSUES   │    │  4. RUN TESTS    │
      │  (general agent) │    │  (test runner)   │
      └──────────────────┘    └──────────────────┘
                │                       │
                │                 ┌─────┴─────┐
                │                 │           │
                │                 ▼           ▼
                │            ┌────────┐  ┌────────┐
                └───────────▶│  Pass  │  │  Fail  │
                (max 3x)     └────────┘  └────────┘
                                  │           │
                                  ▼           │
                            ┌──────────┐      │
                            │ SUCCESS  │      │
                            └──────────┘      │
                                              │
                                              └─── Back to step 1
```

### Workflow Steps

1. **Implementation Phase**
   - General-purpose agent implements the task
   - Writes code following team patterns
   - Includes initial test coverage

2. **Review Phase**
   - Code-reviewer agent analyzes the implementation
   - Checks for:
     - Security vulnerabilities
     - Code quality issues
     - Pattern violations
     - Missing error handling
     - Test coverage gaps

3. **Fix Phase** (if issues found)
   - General-purpose agent addresses review feedback
   - Maximum 3 iterations to prevent infinite loops
   - Each iteration gets more specific feedback

4. **Testing Phase**
   - Automatic test execution:
     - **Java/Spring Boot**: `mvn test`
     - **Go**: `go test ./...`
     - **Python**: `pytest`
     - **Node.js**: `npm test`
   - Coverage validation (80% minimum)
   - If tests fail, returns to implementation phase

5. **Completion**
   - Summary report with:
     - Number of review iterations
     - Issues found and fixed
     - Test results
     - Files changed

## Hooks

### 1. Pre-User-Prompt Hook

**File**: `hooks/pre-user-prompt/task-complexity-check.sh`

**Triggers**: Before Claude processes user's prompt

**Function**:
- Analyzes user's request for complexity keywords
- Estimates complexity score
- Suggests auto-review-loop if score ≥ 5

**Complexity Keywords**:
- **High**: refactor, redesign, breaking change, saga, event sourcing
- **Moderate**: new endpoint, new API, add feature

**Example Output**:
```bash
🔍 Pre-flight task complexity assessment...

  • Detected: implement authentication (+3 complexity)
  • Detected: new api (+1 complexity)
  • Multi-part task detected (+2 complexity)

Estimated Complexity Score: 6

⚠️  HIGH COMPLEXITY TASK DETECTED

Recommendation: Use auto-review-loop workflow

SUGGESTION: Trigger /auto-review-loop
```

### 2. Pre-Task Hook

**File**: `hooks/pre-task/complexity-assessment.sh`

**Triggers**: Before/during implementation (when git changes detected)

**Function**:
- Analyzes git diff for complexity signals
- Checks file changes, line changes, patterns
- Triggers auto-review-loop for complex changes

**Analysis Includes**:
- Number of files changed
- Lines of code changed
- Packages/modules affected
- Architectural patterns (aggregates, events, APIs)
- Security-related changes
- Infrastructure changes
- Test file presence

**Example Output**:
```bash
🔍 Assessing task complexity...

Complexity Score: 8
Threshold: 5

Complexity Factors:
  • Multiple files changed (5 files)
  • New domain aggregate or entity
  • New API endpoint
  • Security-related changes
  • No test files in change (tests needed)

⚠️  HIGH COMPLEXITY DETECTED

TRIGGER: /auto-review-loop

The auto-review-loop skill will:
  1. Implement the changes
  2. Run code review (everything-claude-code:code-reviewer)
  3. Fix any issues found
  4. Repeat steps 2-3 until LGTM
  5. Run automated tests
  6. Report results
```

## Usage

### Automatic Trigger (Recommended)

The hooks automatically detect complexity:

```bash
# User makes a request
User: "Implement OAuth2 authentication with JWT tokens and role-based access control"

# Pre-user-prompt hook runs
🔍 Pre-flight task complexity assessment...
Estimated Complexity Score: 9
⚠️  HIGH COMPLEXITY TASK DETECTED
SUGGESTION: Trigger /auto-review-loop

# Claude or user can then trigger
Claude: Let me implement this using the auto-review-loop workflow to ensure quality...
```

### Manual Trigger

User can explicitly request auto-review-loop:

```bash
# Direct invocation
/auto-review-loop implement user authentication with OAuth2

# Or natural language
"auto implement the payment processing saga"
"implement with review loop: event sourcing for orders"
```

### Configuring Thresholds

Edit hook configuration variables:

**In `hooks/pre-task/complexity-assessment.sh`**:
```bash
COMPLEXITY_THRESHOLD=5  # Trigger auto-review-loop if score >= threshold
MAX_FILES_SIMPLE=3      # More than this = complex
MAX_LINES_SIMPLE=200    # More than this = complex
```

**In `hooks/pre-user-prompt/task-complexity-check.sh`**:
```bash
# Adjust keyword lists and scoring
COMPLEX_KEYWORDS=(...)
MODERATE_KEYWORDS=(...)
```

## Benefits

### Quality Assurance
- **Automatic code review** catches issues early
- **Iterative improvement** ensures clean code
- **Test coverage** enforced automatically
- **Pattern compliance** verified by reviewer

### Risk Reduction
- **Complex changes** get extra scrutiny
- **Security issues** caught before commit
- **Breaking changes** thoroughly reviewed
- **Test failures** fixed before completion

### Consistency
- **Same workflow** for all engineers
- **Standard quality bar** across services
- **Automated enforcement** removes human error
- **Documentation** of review process

### Efficiency
- **Automated iteration** faster than manual review
- **Parallel testing** reduces wait time
- **Clear feedback** guides improvements
- **No context switching** for engineers

## Examples

### Example 1: Simple Task (No Auto-Review-Loop)

**Task**: "Fix typo in error message"

**Assessment**:
- 1 file changed
- 2 lines changed
- No architectural changes

**Score**: 0

**Result**: Standard workflow, no auto-review-loop

---

### Example 2: Moderate Task (Recommended)

**Task**: "Add validation to order submission endpoint"

**Assessment**:
- 2 files changed (controller, test)
- API endpoint modified
- 50 lines changed

**Score**: 3

**Result**: Moderate complexity, extra attention recommended

---

### Example 3: Complex Task (Auto-Review-Loop Required)

**Task**: "Implement payment processing saga with event sourcing"

**Assessment**:
- 8 files changed
- New aggregate (Payment)
- Kafka integration
- Saga pattern
- Event sourcing
- 450 lines changed
- Security-related (payment)

**Score**: 11

**Result**: High complexity - auto-review-loop triggered

**Output**:
```
Iteration 1:
  - Implemented payment saga
  - Review: Missing idempotency check, error handling incomplete

Iteration 2:
  - Added idempotency with processed events table
  - Added compensation handlers
  - Review: LGTM, but test coverage at 65%

Iteration 3:
  - Added tests for compensation logic
  - Test coverage: 82%
  - Review: LGTM

Tests: ✅ All pass (45/45)
Coverage: 82%

Success! Implemented in 3 iterations.
```

## Integration with Other Hooks

The complexity assessment hooks work alongside:

- **security-check.sh**: Security review for sensitive changes
- **test-coverage.sh**: Enforce 80% minimum coverage
- **schema-validation.sh**: Validate event schema changes
- **domain-review.sh**: DDD pattern compliance

**Combined Example**:
```bash
# Complex task with security and schema changes
Task: "Add customer authentication with event publishing"

# Complexity assessment
Score: 9 (security + new API + event schema)
→ Triggers auto-review-loop

# Within auto-review-loop iterations
→ Security review triggers (auth changes detected)
→ Schema validation triggers (new event schema)
→ Test coverage enforced (80% minimum)
→ Domain review triggers (new event published)

Result: Comprehensive quality gates applied automatically
```

## Customization

### Adding Custom Complexity Signals

Edit `hooks/pre-task/complexity-assessment.sh`:

```bash
# Add custom pattern detection
if git diff --cached | grep -qE "YourCustomPattern"; then
    add_complexity 2 "Custom pattern detected"
fi
```

### Team-Specific Keywords

Edit `hooks/pre-user-prompt/task-complexity-check.sh`:

```bash
# Add team-specific keywords
COMPLEX_KEYWORDS+=(
    "your-critical-service"
    "legacy-integration"
    "regulatory-compliance"
)
```

### Adjusting Workflow

Edit `skills/auto-review-loop/SKILL.md`:

- Change `max_iterations` default
- Add team-specific review criteria
- Customize test commands
- Add deployment steps

## Monitoring and Metrics

Track complexity assessment effectiveness:

**Metrics to Collect**:
- Average complexity score per task
- Auto-review-loop trigger rate
- Average iterations needed
- Test success rate
- Issue types caught by reviewer

**Example Dashboard**:
```
Tasks This Sprint: 47
├─ Simple (score < 3): 32 (68%)
├─ Moderate (score 3-4): 9 (19%)
└─ Complex (score ≥ 5): 6 (13%)
   └─ Auto-review-loop triggered: 6/6 (100%)
      ├─ Average iterations: 2.3
      ├─ Issues caught: 18
      └─ All tests passed: 6/6 (100%)
```

## Troubleshooting

### Hook Not Triggering

**Check**:
1. Hook is executable: `chmod +x hooks/pre-task/*.sh`
2. Hook directory configured in `settings.json`
3. Git repository initialized

### False Positives

**Issue**: Simple tasks marked as complex

**Solution**:
- Adjust `COMPLEXITY_THRESHOLD` in hook
- Review keyword lists
- Check scoring weights

### Auto-Review-Loop Failures

**Issue**: Loop exceeds max iterations

**Solution**:
- Check review feedback specificity
- Verify test setup is correct
- Increase `max_iterations` if needed
- Manual intervention if truly blocked

## Best Practices

### ✅ Do:
- Trust the complexity assessment
- Use auto-review-loop for scores ≥ 5
- Review hook configuration quarterly
- Collect metrics on effectiveness
- Adjust thresholds based on team experience

### ❌ Don't:
- Skip auto-review-loop for complex tasks
- Set threshold too high (misses complex tasks)
- Set threshold too low (wastes time)
- Ignore hook suggestions
- Disable hooks without team discussion

## Related Documentation

- [Auto-Review-Loop Skill](../skills/auto-review-loop/SKILL.md)
- [Code Review Patterns](PATTERNS.md#code-review)
- [Testing Standards](PATTERNS.md#testing-standards)
- [Contributing Guidelines](CONTRIBUTING.md)

## References

- Complexity Metrics: Cyclomatic Complexity, Lines of Code
- Code Review Research: Google Engineering Practices
- Test-Driven Development: Kent Beck
- Continuous Integration: Martin Fowler
