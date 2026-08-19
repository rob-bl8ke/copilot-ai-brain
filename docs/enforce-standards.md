# Enforcement Mechanisms

How team standards are automatically enforced through hooks and agents.

---

## Enforcement Levels

### Level 1: Suggestion (Pre-User-Prompt)

**When:** Before Claude processes request

**Mechanism:** `agent-router.sh` analyzes keywords and suggests skills/agents

**Action:** Recommendation only, not blocking

**Example:**
```bash
User: "Implement payment processing"
     ↓
Hook: Suggests security-reviewer, architect
     ↓
Claude: May invoke agents (not guaranteed)
```

---

### Level 2: Warning (Pre-Commit)

**When:** Before git commit

**Mechanism:** Hooks detect patterns in git diff

**Action:** Shows warnings, triggers agent review (non-blocking)

**Example:**
```bash
git commit -m "Add payment endpoint"
     ↓
Hook: Detects @PostMapping
     ↓
TRIGGER: Security review required
     ↓
Claude: Runs security-reviewer agent
     ↓
Finds issues → Fix required
```

---

### Level 3: Blocking (Pre-Commit with exit 1)

**When:** Critical violations detected

**Mechanism:** Hook exits with code 1 to block commit

**Action:** Commit rejected, must fix to proceed

**Currently:** Not enabled (all hooks use exit 0)

**To enable:** Change `exit 0` to `exit 1` in hook

---

## Enforcement by Category

### 🔒 Security (Full Enforcement)

**Hook:** `hooks/pre-commit/security-check.sh`

**Triggers on:**
- API endpoint changes (`@PostMapping`, `@GetMapping`)
- Security annotations (`@PreAuthorize`, `@Secured`)
- Database queries (`JdbcTemplate`, `@Query`)
- External API calls (`RestTemplate`, `WebClient`)

**Action:**
```bash
HOOK: API endpoint changes detected
TRIGGER: Security review required
→ Invokes security-reviewer agent
→ Scans for OWASP Top 10
→ Reports vulnerabilities
```

**Enforcement:** Warning (exit 0) - can change to blocking (exit 1)

---

### 🏛️  Architecture (Warning Enforcement)

**Hook:** `hooks/pre-commit/architecture-check.sh` ⭐ NEW

**Triggers on:**
- Domain layer importing framework code (`javax.persistence`, `org.springframework`)
- Application layer depending on infrastructure (direct imports)
- God classes (>500 lines)
- Anemic domain model (setters in domain entities)
- Type switching (violates OCP)
- Dependency rule violations

**Action:**
```bash
❌ LAYER VIOLATION: Domain depends on infrastructure
TRIGGER: Architect agent review
→ Shows violation details
→ Provides fix recommendations
→ Suggests /clean-architecture analyze
```

**Enforcement:** Warning (exit 0) - can change to blocking (exit 1)

**Example Output:**
```bash
❌ LAYER VIOLATION: Domain depends on infrastructure

Domain layer must be framework-agnostic.
Remove these imports from domain layer:
  • javax.persistence.* (@Entity, @Id, @Column)
  • org.springframework.data.* (JPA repositories)

Fix:
  1. Remove framework annotations from domain entities
  2. Create separate JPA entities in infrastructure layer
  3. Use mapper to convert between domain and JPA entities

TRIGGER: Architect agent review
```

---

### 🧩 SOLID (Reminder)

**Hook:** `hooks/post-code/solid-check.sh` ⭐ NEW

**Triggers on:**
- Any Java file changes

**Action:**
```bash
🧩 SOLID Principles Checklist

1️⃣  Single Responsibility Principle (SRP)
   ✓ Does each class have one reason to change?
   ⚠️  Service detected - ensure it's not a god class

2️⃣  Open/Closed Principle (OCP)
   ⚠️  Type switching detected - consider polymorphism

[... continues for all 5 principles]
```

**Enforcement:** Reminder only (post-code, informational)

---

### 🎯 Complexity (Automatic Trigger)

**Hook:** `hooks/pre-task/complexity-assessment.sh`

**Triggers on:**
- Complexity score ≥ 5

**Action:**
```bash
⚠️  HIGH COMPLEXITY DETECTED
TRIGGER: /auto-review-loop
→ Automatically invokes skill
→ Iterative code → review → fix → test cycle
```

**Enforcement:** Automatic skill invocation

---

### ✅ Test Coverage (Warning)

**Hook:** `hooks/pre-commit/test-coverage.sh`

**Triggers on:**
- Java files changed without corresponding test files

**Action:**
```bash
TRIGGER: Missing test files detected
→ Reminder to add tests
→ Coverage requirement: 80%
```

**Enforcement:** Warning (exit 0)

---

### 📋 Schema Validation (Warning)

**Hook:** `hooks/pre-commit/schema-validation.sh`

**Triggers on:**
- Schema file changes (`.avsc`, `.proto`)

**Action:**
```bash
TRIGGER: Schema validation required
→ Check compatibility
→ Verify backward compatibility
```

**Enforcement:** Warning (exit 0)

---

### 🏗️  DDD Compliance (Reminder)

**Hook:** `hooks/post-code/domain-review.sh`

**Triggers on:**
- Entity, Aggregate, ValueObject file changes
- Repository changes
- Service changes

**Action:**
```bash
DDD Checklist:
  ✓ Entities have identity and lifecycle
  ✓ Value Objects are immutable
  ✓ Aggregates enforce consistency boundaries
```

**Enforcement:** Reminder only (post-code, informational)

---

## Enforcement Flow Examples

### Example 1: Security Violation

```bash
Developer: git commit -m "Add payment endpoint"
     ↓
pre-commit/security-check.sh runs
     ↓
Detects: @PostMapping("/api/payment")
     ↓
Output:
  HOOK: API endpoint changes detected
  TRIGGER: Security review required
     ↓
Claude sees trigger
     ↓
Invokes: security-reviewer agent
     ↓
Agent output:
  🚨 CRITICAL: SQL injection risk
  🚨 CRITICAL: No input validation
  ⚠️  HIGH: Missing @PreAuthorize
     ↓
Developer must fix
     ↓
Re-commit after fixes
```

---

### Example 2: Architecture Violation

```bash
Developer: git commit -m "Add Order entity"
     ↓
pre-commit/architecture-check.sh runs
     ↓
Detects: @Entity in domain/model/Order.java
     ↓
Output:
  ❌ LAYER VIOLATION: Domain depends on infrastructure

  Domain layer must be framework-agnostic.
  Remove: @Entity, @Id, @Column

  Fix:
    1. Remove JPA annotations from domain
    2. Create OrderEntity in infrastructure
    3. Use mapper: OrderEntity ↔ Order

  TRIGGER: Architect agent review
     ↓
Claude sees trigger
     ↓
Invokes: architect agent
     ↓
Agent output:
  Layer Structure Issues:
  - Domain violates independence principle
  - Infrastructure not properly isolated

  Recommended Refactoring:
  1. Create infrastructure/persistence/OrderEntity.java
  2. Add infrastructure/persistence/OrderMapper.java
  3. Remove annotations from domain/model/Order.java
     ↓
Developer refactors
     ↓
Re-commit after fixes
```

---

### Example 3: SOLID Violation

```bash
Developer: Implements PaymentProcessor
     ↓
git commit
     ↓
pre-commit/architecture-check.sh runs
     ↓
Detects: switch (payment.getType())
     ↓
Output:
  ⚠️  SOLID VIOLATION: Type switching (OCP)

  Switching on type violates Open/Closed Principle.

  Fix:
    1. Create PaymentProcessor interface
    2. Implement CreditCardProcessor
    3. Implement EFTProcessor
    4. Use polymorphism
     ↓
post-code/solid-check.sh runs after commit
     ↓
Output:
  2️⃣  Open/Closed Principle (OCP)
     ⚠️  Type switching detected - consider polymorphism
     ✓ Can you extend behavior without modifying code?
     ✓ Are you using interfaces/abstractions?
     ↓
Developer sees reminder
     ↓
May refactor in next iteration
```

---

### Example 4: Complexity Triggers Auto-Review-Loop

```bash
User: "Implement payment saga with event sourcing"
     ↓
pre-user-prompt/agent-router.sh
     ↓
Suggests: /auto-review-loop, architect, security-reviewer
     ↓
Claude starts implementation
     ↓
pre-task/complexity-assessment.sh runs
     ↓
Calculates complexity score: 11
  • 8 files changed (+2)
  • Saga pattern (+3)
  • Event sourcing (+3)
  • Kafka (+2)
  • Security (+3)
     ↓
Score ≥ 5 → TRIGGER: /auto-review-loop
     ↓
Auto-review-loop workflow:
  1. Implement saga
  2. code-reviewer: Finds missing idempotency
  3. Fix issues
  4. code-reviewer: LGTM
  5. security-reviewer: Runs (payment detected)
  6. Fix security issues
  7. Run tests
  8. Success
```

---

## Blocking vs Warning Mode

### Current State (All Warnings)

All hooks use `exit 0` → warnings only, non-blocking

**Pros:**
- Doesn't interrupt developer flow
- Provides guidance without force
- Allows exceptions when needed

**Cons:**
- Violations can be ignored
- Standards not strictly enforced
- Depends on developer discipline

---

### Blocking Mode (Strict Enforcement)

Change `exit 0` to `exit 1` in critical hooks

**Pros:**
- Guarantees standards compliance
- Forces fixes before commit
- No exceptions possible

**Cons:**
- Can slow down development
- May be frustrating for quick fixes
- Requires mature team practices

---

### Recommended Approach

**Start with warnings (exit 0):**
- Team learns patterns
- Builds awareness
- Collects metrics

**Gradually enable blocking (exit 1):**
- After 2-4 weeks of warnings
- When team familiar with patterns
- For critical violations only:
  - Security issues (OWASP Top 10)
  - Domain layer dependencies
  - Missing tests (below 80%)

**Selective blocking:**
```bash
# Security - always block
if [ "$CRITICAL_SECURITY_ISSUE" = "yes" ]; then
    exit 1  # Block commit
fi

# Architecture - warn only
exit 0  # Allow commit with warning
```

---

## How to Enable Blocking

### Step 1: Choose Hook to Make Blocking

**Options:**
- `security-check.sh` → Block security violations
- `architecture-check.sh` → Block layer violations
- `test-coverage.sh` → Block below 80% coverage

### Step 2: Edit Hook

```bash
# Open hook file
vi hooks/pre-commit/architecture-check.sh

# Find the exit statement
# Change from:
exit 0  # Warning only

# To:
exit 1  # Block commit
```

### Step 3: Test

```bash
# Make a violation
echo "@Entity" >> domain/model/Order.java
git add .
git commit -m "Test blocking"

# Should see:
# ❌ LAYER VIOLATION: Domain depends on infrastructure
# error: hook failed
# Commit blocked
```

### Step 4: Fix and Retry

```bash
# Remove violation
git diff HEAD  # Verify fix
git commit -m "Fixed layer violation"
# ✅ Commit succeeds
```

---

## Enforcement Metrics

Track these to measure effectiveness:

| Metric | Target | Purpose |
|--------|--------|---------|
| Violations detected | Track trend | Are violations decreasing? |
| Violations fixed | >90% | Are developers responding? |
| Time to fix | <1 hour | Is guidance clear? |
| False positives | <10% | Are checks accurate? |
| Developer satisfaction | >4/5 | Is enforcement helpful? |

**Collection:**
```bash
# Log violations
echo "$(date): architecture violation - domain dependency" >> ~/violations.log

# Weekly review
cat ~/violations.log | grep "$(date -d '7 days ago' +%Y-%m)"
```

---

## Customization

### Add Custom Check

**Example: Detect missing @Transactional**

```bash
# In hooks/pre-commit/architecture-check.sh

# Check for missing @Transactional
if git diff --cached --diff-filter=AM | grep -E "save\(|delete\("; then
    if ! git diff --cached --diff-filter=AM | grep -qE "@Transactional"; then
        echo "⚠️  Missing @Transactional on method with save/delete"
        echo "Add @Transactional to ensure atomicity"
    fi
fi
```

### Adjust Thresholds

```bash
# God class threshold
LARGE_FILES_THRESHOLD=500  # Change to 300 for stricter

# Complexity threshold
COMPLEXITY_THRESHOLD=5  # Change to 3 for stricter
```

### Add Team-Specific Rules

```bash
# Example: Enforce naming convention
if git diff --cached --name-only | grep -E "Service\.java$"; then
    if ! git diff --cached | grep -qE "class.*UseCase"; then
        echo "⚠️  Service classes should end with 'UseCase'"
    fi
fi
```

---

## Troubleshooting

### Hook Not Running

**Check:**
```bash
# 1. Hook is executable
ls -la hooks/pre-commit/*.sh

# 2. Hook is in correct location
ls ~/.claude/hooks/  # Should symlink to team config

# 3. Git hooks enabled
git config --get core.hooksPath
```

### False Positives

**Solution:**
```bash
# Add exception
if echo "$file" | grep -qE "test/|Test\.java$"; then
    # Skip tests
    continue
fi
```

### Hook Too Slow

**Solution:**
```bash
# Limit files checked
CHANGED_FILES=$(git diff --cached --name-only | head -50)

# Add timeout
timeout 5s git diff ...
```

---

## Summary

### Enforcement Mechanisms

| Mechanism | When | Type | Blocking |
|-----------|------|------|----------|
| agent-router.sh | Pre-prompt | Suggestion | No |
| security-check.sh | Pre-commit | Warning | No (can enable) |
| architecture-check.sh | Pre-commit | Warning | No (can enable) |
| solid-check.sh | Post-code | Reminder | No |
| complexity-assessment.sh | Pre-task | Auto-trigger | Yes (auto-review-loop) |
| test-coverage.sh | Pre-commit | Warning | No (can enable) |
| schema-validation.sh | Pre-commit | Warning | No (can enable) |
| domain-review.sh | Post-code | Reminder | No |

### Current State

- ✅ Full suggestion system (agent-router)
- ✅ Security enforcement (warning)
- ✅ Architecture enforcement (warning) ⭐ NEW
- ✅ SOLID enforcement (reminder) ⭐ NEW
- ✅ Complexity auto-trigger
- ⚠️  No blocking mode (can enable)

### Recommended Next Steps

1. **Run warning mode for 2 weeks**
2. **Collect metrics on violations**
3. **Enable blocking for critical violations**
4. **Iterate based on team feedback**

---

**Last Updated:** 2026-05-18
**Enforcement Version:** 1.0
