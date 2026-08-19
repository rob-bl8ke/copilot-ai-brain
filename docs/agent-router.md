# Agent Integration Guide

How the 13 specialized agents integrate with team hooks, skills, and workflows.

## Integration Overview

```
Team Hooks → Detect Patterns → Trigger Agents → Enforce Standards
     ↓
Team Skills → Wrap Agents → Simplify Usage → Team Workflows
     ↓
Agent Output → Feed Back → Iterate → Quality Gates
```

---

## Hook → Agent Mappings

### Pre-Commit Hooks

**1. security-check.sh** → `security-reviewer` agent

```bash
# Trigger Conditions:
- API endpoint changes (@RestController, @PostMapping, etc.)
- Security annotations (@PreAuthorize, @Secured, etc.)
- Database queries (createQuery, JdbcTemplate, etc.)
- External API calls (RestTemplate, WebClient, etc.)

# What Happens:
hooks/pre-commit/security-check.sh
→ Detects security-sensitive changes
→ Triggers: Task(subagent_type="everything-claude-code:security-reviewer")
→ Agent scans for OWASP Top 10, secrets, injection vulnerabilities
→ Returns: CRITICAL/HIGH/MEDIUM findings
→ Blocks commit if CRITICAL issues found
```

**Example Flow:**
```
Developer: git commit -m "Add payment endpoint"
     ↓
Hook: Detects @PostMapping in diff
     ↓
Agent: security-reviewer runs
     ↓
Finding: SQL injection risk detected
     ↓
Result: Commit blocked, fix required
```

---

**2. test-coverage.sh** → `tdd-guide` agent (if coverage < 80%)

```bash
# Trigger Conditions:
- Java files changed (.java)
- Test coverage < 80%

# What Happens:
hooks/pre-commit/test-coverage.sh
→ Runs JaCoCo coverage check
→ If < 80%, suggests: Task(subagent_type="everything-claude-code:tdd-guide")
→ Agent generates missing tests
→ Returns: Test templates
→ Re-run coverage check
```

---

**3. schema-validation.sh** → `database-reviewer` agent (optional)

```bash
# Trigger Conditions:
- Schema file changes (.avsc, .proto)
- Migration files (flyway, liquibase)

# What Happens:
hooks/pre-commit/schema-validation.sh
→ Validates schema syntax
→ Optionally triggers: Task(subagent_type="everything-claude-code:database-reviewer")
→ Agent checks schema design, indexes, constraints
→ Returns: Optimization recommendations
```

---

### Pre-Task Hooks

**4. complexity-assessment.sh** → `auto-review-loop` skill → `code-reviewer` agent

```bash
# Trigger Conditions:
- Complexity score ≥ 5

# What Happens:
hooks/pre-task/complexity-assessment.sh
→ Calculates complexity score
→ If ≥ 5, triggers: /auto-review-loop
→ Skill spawns: Task(subagent_type="everything-claude-code:code-reviewer")
→ Agent reviews code quality, security, maintainability
→ Iterates until LGTM
→ Runs tests
→ Reports results
```

**Complexity Triggers:**
```
Score 7: Multiple files (5+) + New API endpoint + Security code
     ↓
auto-review-loop triggered
     ↓
Iteration 1: code-reviewer finds issues
     ↓
Fix issues
     ↓
Iteration 2: code-reviewer LGTM
     ↓
Run tests → Pass → Success
```

---

### Post-Code Hooks

**5. domain-review.sh** → `architect` agent (optional)

```bash
# Trigger Conditions:
- Domain model changes (aggregate, entity, value object)
- Bounded context violations

# What Happens:
hooks/post-code/domain-review.sh
→ Detects DDD pattern changes
→ Optionally triggers: Task(subagent_type="everything-claude-code:architect")
→ Agent reviews architecture, DDD boundaries
→ Returns: Architecture feedback
```

---

## Skill → Agent Mappings

### auto-review-loop

**Primary Agent:** `code-reviewer`

**Optional Agents (triggered by detected patterns):**
- `security-reviewer` - If API/auth code detected
- `go-reviewer` - If Go files detected
- `python-reviewer` - If Python files detected
- `database-reviewer` - If SQL/schema changes detected

**Workflow:**
```
/auto-review-loop implement feature
     ↓
1. General-purpose agent implements
     ↓
2. code-reviewer agent reviews
     ↓
3. security-reviewer agent (if API changes)
     ↓
4. go-reviewer agent (if Go files)
     ↓
5. Iterate until all agents LGTM
     ↓
6. Run tests
     ↓
7. Report results
```

---

### go-review (Custom Skill)

**Primary Agent:** `go-reviewer`

**Secondary Agent:** `go-build-resolver` (if build issues)

**Usage:**
```bash
/go-review
```

**What Happens:**
```
1. Run git diff to see Go changes
2. Trigger: Task(subagent_type="everything-claude-code:go-reviewer")
3. Agent checks:
   - Idiomatic Go patterns
   - Concurrency safety
   - Error handling
   - Performance
4. If build issues: Task(subagent_type="everything-claude-code:go-build-resolver")
5. Report findings
```

**Create this skill:**
```markdown
# go-review

Comprehensive Go code review using go-reviewer agent

## Trigger
- User says "review go code"
- User invokes `/go-review`
- User says "go code review"

## Workflow
1. Run git diff to identify Go file changes
2. Spawn Task(subagent_type="everything-claude-code:go-reviewer")
3. If build issues detected, spawn Task(subagent_type="everything-claude-code:go-build-resolver")
4. Report findings in priority order (Critical → Warnings → Suggestions)
```

---

### python-review (Custom Skill)

**Primary Agent:** `python-reviewer`

**Usage:**
```bash
/python-review
```

**What Happens:**
```
1. Run git diff to see Python changes
2. Trigger: Task(subagent_type="everything-claude-code:python-reviewer")
3. Agent checks:
   - PEP 8 compliance
   - Pythonic idioms
   - Type hints
   - Security vulnerabilities
4. Report findings
```

**Create this skill:**
```markdown
# python-review

Comprehensive Python code review using python-reviewer agent

## Trigger
- User says "review python code"
- User invokes `/python-review`
- User says "python code review"

## Workflow
1. Run git diff to identify Python file changes
2. Spawn Task(subagent_type="everything-claude-code:python-reviewer")
3. Report findings in priority order (Critical → Warnings → Suggestions)
```

---

### security-review (Custom Skill)

**Primary Agent:** `security-reviewer`

**Usage:**
```bash
/security-review
```

**What Happens:**
```
1. Run git diff to see API/auth changes
2. Trigger: Task(subagent_type="everything-claude-code:security-reviewer")
3. Agent checks:
   - OWASP Top 10
   - Hardcoded secrets
   - Input validation
   - SQL injection
   - XSS, CSRF, SSRF
4. Run security tools (npm audit, trufflehog)
5. Report vulnerabilities by severity
```

**Create this skill:**
```markdown
# security-review

Security vulnerability detection using security-reviewer agent

## Trigger
- User says "security review"
- User invokes `/security-review`
- User says "check for vulnerabilities"
- Pre-commit hook detects security-sensitive changes

## Workflow
1. Run git diff to identify security-sensitive changes
2. Spawn Task(subagent_type="everything-claude-code:security-reviewer")
3. Agent runs security scans:
   - npm audit (dependencies)
   - trufflehog (secrets)
   - Pattern matching (injection, XSS, etc.)
4. Report findings by severity (CRITICAL → HIGH → MEDIUM → LOW)
5. Provide fix recommendations
```

---

## Agent Orchestration Patterns

### Pattern 1: Sequential Review Chain

Use when order matters (fix build before reviewing code):

```bash
1. go-build-resolver → Fix build
     ↓
2. go-reviewer → Review code quality
     ↓
3. security-reviewer → Check vulnerabilities
     ↓
4. database-reviewer → Optimize queries
```

**Implementation:**
```bash
# In skill or hook:
Task(subagent_type="everything-claude-code:go-build-resolver", ...)
# Wait for completion
Task(subagent_type="everything-claude-code:go-reviewer", ...)
# Wait for completion
Task(subagent_type="everything-claude-code:security-reviewer", ...)
```

---

### Pattern 2: Parallel Review Execution

Use when reviews are independent (faster feedback):

```bash
       ┌─ code-reviewer
       │
Start ─┼─ security-reviewer  → Aggregate Results
       │
       └─ go-reviewer
```

**Implementation:**
```bash
# Single message with multiple Task calls:
Task(subagent_type="everything-claude-code:code-reviewer", ...)
Task(subagent_type="everything-claude-code:security-reviewer", ...)
Task(subagent_type="everything-claude-code:go-reviewer", ...)
```

---

### Pattern 3: Conditional Agent Triggering

Use when agent depends on detected patterns:

```bash
Detect Changes
     ↓
API changes? → YES → security-reviewer
     ↓
SQL changes? → YES → database-reviewer
     ↓
Go files? → YES → go-reviewer
     ↓
Python files? → YES → python-reviewer
```

**Implementation:**
```bash
# In hook or skill:
if git diff --cached --name-only | grep -E "\.go$"; then
    Task(subagent_type="everything-claude-code:go-reviewer", ...)
fi

if git diff --cached | grep -E "@PostMapping|@GetMapping"; then
    Task(subagent_type="everything-claude-code:security-reviewer", ...)
fi
```

---

## Agent + Hook Examples

### Example 1: New API Endpoint

**Code:**
```java
@RestController
public class PaymentController {
    @PostMapping("/api/payments")
    public Response createPayment(@RequestBody PaymentRequest req) {
        String sql = "INSERT INTO payments VALUES ('" + req.getAmount() + "')";
        jdbcTemplate.execute(sql);
        return Response.ok();
    }
}
```

**Hook Flow:**
```bash
git commit -m "Add payment endpoint"
     ↓
hooks/pre-commit/security-check.sh
     ↓
Detects: @PostMapping, @RequestBody, JdbcTemplate
     ↓
Triggers: security-reviewer agent
     ↓
Agent Findings:
  🚨 CRITICAL: SQL injection via string concatenation
  🚨 CRITICAL: No input validation on PaymentRequest
  ⚠️  HIGH: Missing @PreAuthorize annotation
  ⚠️  HIGH: No rate limiting
     ↓
Commit BLOCKED → Fix required
```

---

### Example 2: Complex Saga Implementation

**Task:**
```
Implement payment processing saga with event sourcing
```

**Hook Flow:**
```bash
hooks/pre-task/complexity-assessment.sh
     ↓
Signals Detected:
  • 8 files changed (+2)
  • Saga pattern (+3)
  • Event sourcing (+3)
  • Kafka integration (+2)
  • Security-related (+3)
     ↓
Complexity Score: 13 (threshold: 5)
     ↓
Triggers: /auto-review-loop
     ↓
Iteration 1:
  - Implement saga logic
  - architect agent reviews architecture
  - code-reviewer finds missing idempotency
     ↓
Iteration 2:
  - Add idempotency keys
  - security-reviewer finds missing encryption
     ↓
Iteration 3:
  - Add encryption
  - database-reviewer suggests indexes
     ↓
Iteration 4:
  - Add indexes
  - All agents LGTM
     ↓
Run tests → 85% coverage → Pass
     ↓
Success after 4 iterations
```

---

### Example 3: Go Concurrency Bug

**Code:**
```go
func processOrders(orders []Order) {
    var wg sync.WaitGroup
    results := make(map[string]Result)

    for _, order := range orders {
        wg.Add(1)
        go func(o Order) {
            defer wg.Done()
            results[o.ID] = process(o)  // Race condition!
        }(order)
    }
    wg.Wait()
}
```

**Hook Flow:**
```bash
git commit -m "Add concurrent order processing"
     ↓
hooks/pre-commit/test-coverage.sh
     ↓
Detects: Go files changed
     ↓
Triggers: go-reviewer agent
     ↓
Agent Findings:
  🚨 CRITICAL: Data race - concurrent map writes without mutex
  ⚠️  HIGH: No error handling in goroutines
  ℹ️  SUGGESTION: Consider using sync.Map or channels
     ↓
Fix Recommendation:
  ```go
  results := sync.Map{}
  // or
  mu := sync.Mutex{}
  ```
     ↓
Commit BLOCKED → Fix required
```

---

## Agent Performance Optimization

### 1. Scope Reduction

Instead of reviewing entire repo:

```bash
# Bad (slow)
Task(
  subagent_type="everything-claude-code:code-reviewer",
  prompt="Review the codebase"
)

# Good (fast)
Task(
  subagent_type="everything-claude-code:code-reviewer",
  prompt="Review changes in src/payment/PaymentService.java"
)
```

---

### 2. Model Selection

Use appropriate model for task:

```bash
# Critical security review → Opus (thorough)
Task(
  subagent_type="everything-claude-code:security-reviewer",
  model="opus",
  prompt="..."
)

# Build error fix → Haiku (fast)
Task(
  subagent_type="everything-claude-code:build-error-resolver",
  model="haiku",
  prompt="..."
)
```

---

### 3. Parallel Execution

Run independent agents in parallel:

```bash
# Sequential (slow) - 30 seconds
Task(subagent_type="code-reviewer", ...)      # 10s
Task(subagent_type="security-reviewer", ...)  # 10s
Task(subagent_type="go-reviewer", ...)        # 10s

# Parallel (fast) - 10 seconds
Task(subagent_type="code-reviewer", ...)
Task(subagent_type="security-reviewer", ...)
Task(subagent_type="go-reviewer", ...)
# All run simultaneously
```

---

## Creating Custom Agent Skills

### Template

Create `skills/[agent-name]/SKILL.md`:

```markdown
# [agent-name]

[Description of what this skill does]

## Trigger
- User says "[trigger phrase]"
- User invokes `/[command]`
- Hook detects [pattern]

## Workflow
1. [Preparation step]
2. Spawn Task(subagent_type="everything-claude-code:[agent-name]", prompt="...")
3. [Parse agent output]
4. [Take action based on output]
5. [Report results]

## Parameters
- `scope`: Limit review to specific files (default: all changed files)
- `severity`: Minimum severity to report (default: MEDIUM)

## Example
User: "/[command]"
Agent: [Shows expected output]
```

---

## Testing Agent Integration

### 1. Test Hook Triggers

```bash
# Create test change
echo "// TODO: security risk" > test.java
git add test.java

# Run hook manually
cd ~/team-claude-config
./hooks/pre-commit/security-check.sh

# Expected: Should detect pattern and suggest security-reviewer
```

---

### 2. Test Agent Directly

```bash
# In Claude Code session:
Task(
  subagent_type="everything-claude-code:code-reviewer",
  prompt="Review the test file for security issues"
)

# Expected: Agent returns security findings
```

---

### 3. Test Skill Wrapper

```bash
# In Claude Code session:
/go-review

# Expected: Skill triggers go-reviewer agent and reports findings
```

---

## Troubleshooting

### Hook Not Triggering Agent

**Check:**
1. Hook is executable (`chmod +x hooks/pre-commit/*.sh`)
2. Pattern matching is correct (test with `grep`)
3. Agent name is correct (`everything-claude-code:[agent-name]`)

**Debug:**
```bash
# Add debug output to hook
echo "DEBUG: Triggering agent" >&2
```

---

### Agent Times Out

**Solutions:**
1. Reduce scope (specific files instead of repo)
2. Use lighter model (haiku instead of opus)
3. Increase timeout in Task call

---

### Agent Misses Issues

**Solutions:**
1. Layer multiple agents (code-reviewer + security-reviewer)
2. Provide more context in prompt
3. Run agent directly to debug
4. Check agent version (may need update)

---

## Metrics to Track

| Metric | Target | Purpose |
|--------|--------|---------|
| Hook → Agent trigger rate | 10-20% | Not over-triggering |
| Agent execution time | <30s | Performance |
| Issues caught by agents | >80% | Effectiveness |
| False positives | <20% | Accuracy |
| Iterations to LGTM | <3 | Efficiency |

---

**Last Updated:** 2026-05-18
**Integration Version:** 1.0
