# Agent vs Skill: When to Use Which

Understanding the difference between agents and skills, and when to use each.

---

## Quick Answer

| What | When to Use | How to Invoke |
|------|-------------|---------------|
| **Agent** | Direct specialized review/analysis | `Task(subagent_type="everything-claude-code:agent-name", ...)` |
| **Skill** | Workflow that orchestrates agents/steps | `/skill-name` or via hook trigger |

---

## What Are Agents?

**Agents = Specialized AI workers**

- Autonomous subprocesses with own context
- Spawned via Task tool
- Run independently
- Return focused results
- Single responsibility

**Think:** Hiring a specialist consultant

### Available Agents (13)

```
Code Quality:
  • code-reviewer
  • refactor-cleaner
  • doc-updater

Security:
  • security-reviewer

Architecture:
  • architect
  • planner

Build:
  • build-error-resolver
  • go-build-resolver

Language:
  • go-reviewer
  • python-reviewer

Database:
  • database-reviewer

Testing:
  • tdd-guide
  • e2e-runner
```

### Agent Example

```bash
# Direct agent invocation
Task(
  subagent_type="everything-claude-code:security-reviewer",
  prompt="Review authentication endpoint for vulnerabilities"
)

# Agent does ONE thing:
→ Scans for OWASP Top 10
→ Finds hardcoded secrets
→ Checks input validation
→ Returns vulnerability report
```

---

## What Are Skills?

**Skills = Reusable workflows**

- Orchestrate multiple steps
- Can wrap one or more agents
- Define team patterns
- Encode best practices
- Multi-step procedures

**Think:** Standard operating procedure

### Available Skills (8)

```
Team Skills (~/team-claude-config/skills/):
  • auto-review-loop        - Code → Review → Fix → Test cycle
  • ddd-patterns            - Domain-Driven Design enforcement
  • event-driven-patterns   - Kafka messaging patterns
  • gitops-patterns         - ArgoCD/Helm deployment
  • outbox-core-patterns    - Outbox pattern for consistency
  • persistence-patterns    - Database access patterns
  • schema-registry         - Offline schema validation
  • service-creation        - New service scaffolding
```

### Skill Example

```bash
# Skill invocation
/auto-review-loop implement user authentication

# Skill does MULTIPLE things:
→ Step 1: Implement code (general-purpose agent)
→ Step 2: Review code (code-reviewer agent)
→ Step 3: Check security (security-reviewer agent)
→ Step 4: Fix issues found
→ Step 5: Re-review (iterate max 3x)
→ Step 6: Run tests
→ Step 7: Report results
```

---

## Key Differences

| Aspect | Agent | Skill |
|--------|-------|-------|
| **Purpose** | Specialized analysis | Workflow orchestration |
| **Scope** | Single focused task | Multi-step procedure |
| **Context** | Own isolated context | Shares main context |
| **Invocation** | Task tool | `/skill-name` or hook |
| **Output** | Analysis report | Complete solution |
| **Duration** | Quick (seconds-minutes) | Longer (minutes-hours) |
| **Iteration** | Single pass | Can iterate |

### Analogy

**Agent = Specialist Doctor**
- You go to cardiologist for heart issue
- They examine ONE system
- Give focused diagnosis
- Return results

**Skill = Hospital Protocol**
- Patient arrives → Triage
- Initial assessment → Tests
- Specialist consultation (agent!)
- Treatment → Follow-up
- Multi-step orchestrated process

---

## When to Use Agents Directly

### ✅ Use Agent When:

**1. Need Specialized Review**
```
Task: "Check this code for security vulnerabilities"
Use: security-reviewer agent
Why: Focused security analysis
```

**2. Single Domain Expertise**
```
Task: "Review Go concurrency patterns"
Use: go-reviewer agent
Why: Language-specific expertise
```

**3. Quick Feedback**
```
Task: "Is this SQL query optimized?"
Use: database-reviewer agent
Why: Fast, focused answer
```

**4. Part of Larger Workflow**
```
# Within a skill or custom workflow
Step 1: Implement
Step 2: Task(subagent_type="code-reviewer", ...)  ← Agent
Step 3: Task(subagent_type="security-reviewer", ...) ← Agent
Step 4: Deploy
```

**5. Hook-Triggered Analysis**
```
git commit → security-check.sh detects API
         → Triggers security-reviewer agent
         → Returns findings
```

### Examples

**Security Review:**
```bash
# Direct agent use
Task(
  subagent_type="everything-claude-code:security-reviewer",
  prompt="Review payment endpoint"
)

Result: Vulnerability report in 30 seconds
```

**Go Code Review:**
```bash
# Direct agent use
Task(
  subagent_type="everything-claude-code:go-reviewer",
  prompt="Review worker pool implementation"
)

Result: Idiomatic Go suggestions in 45 seconds
```

**Architecture Analysis:**
```bash
# Direct agent use
Task(
  subagent_type="everything-claude-code:architect",
  prompt="Review microservices communication patterns"
)

Result: Architecture recommendations in 2 minutes
```

---

## When to Use Skills

### ✅ Use Skill When:

**1. Complex Multi-Step Task**
```
Task: "Implement OAuth2 authentication"
Use: /auto-review-loop
Why: Needs implementation + review + testing
```

**2. Enforce Team Process**
```
Task: "Add new domain aggregate"
Use: /ddd-patterns
Why: Ensures DDD boundaries, naming, patterns
```

**3. Complexity Triggers Auto-Flow**
```
Complexity score ≥ 5
Use: /auto-review-loop (triggered by hook)
Why: Complex changes need iterative review
```

**4. Standard Workflow**
```
Task: "Create new microservice"
Use: /service-creation
Why: Scaffolds structure + dependencies + configs
```

**5. Multiple Agents Needed**
```
Task: "Implement payment saga"
Use: Custom skill that orchestrates:
  - architect (design)
  - security-reviewer (payment security)
  - database-reviewer (transaction handling)
  - code-reviewer (quality)
  - tdd-guide (tests)
```

### Examples

**Auto-Review-Loop (Most Common Skill):**
```bash
/auto-review-loop implement user registration

Workflow:
1. Implement registration logic
2. code-reviewer agent reviews
3. Fix issues found
4. security-reviewer agent (API detected)
5. Fix security issues
6. code-reviewer agent re-reviews
7. LGTM → Run tests
8. Tests pass → Success

Result: Fully reviewed + tested code in 5-10 minutes
```

**Service Creation:**
```bash
/service-creation create payment-service

Workflow:
1. Scaffold Spring Boot structure
2. Add Maven dependencies
3. Create DDD package structure
4. Generate application.yml
5. Add Dockerfile + Helm charts
6. Create CI/CD pipeline config
7. Generate README

Result: Production-ready service skeleton in 2 minutes
```

**DDD Patterns:**
```bash
/ddd-patterns add order aggregate

Workflow:
1. Verify bounded context
2. Check aggregate naming
3. Ensure value objects
4. Validate repository pattern
5. Check event publishing
6. architect agent reviews design

Result: DDD-compliant aggregate in 3 minutes
```

---

## Decision Tree

```
┌─────────────────────────┐
│  Need to accomplish X   │
└───────────┬─────────────┘
            │
            ▼
    ┌───────────────┐
    │ Single-domain │
    │   analysis?   │
    └───────┬───────┘
            │
     ┌──────┴──────┐
     │             │
    YES           NO
     │             │
     ▼             ▼
┌─────────┐   ┌──────────┐
│  AGENT  │   │  SKILL   │
└─────────┘   └──────────┘
     │             │
     │             ▼
     │     ┌──────────────┐
     │     │ Multi-step   │
     │     │  workflow?   │
     │     └──────┬───────┘
     │            │
     │      ┌─────┴─────┐
     │      │           │
     │     YES         NO
     │      │           │
     │      ▼           ▼
     │  ┌────────┐  ┌──────────┐
     │  │ SKILL  │  │ AGENT(s) │
     │  └────────┘  └──────────┘
     │      │           │
     ▼      ▼           ▼
  Use    Use         Use
 Task   /skill      Task
 tool              tool
               (multiple)
```

---

## Current Hook Routing

### Hooks → Skills

**1. Complexity Hook → auto-review-loop Skill**
```bash
hooks/pre-task/complexity-assessment.sh
     ↓
If complexity ≥ 5:
  TRIGGER: /auto-review-loop
     ↓
Skill orchestrates:
  → code-reviewer agent
  → security-reviewer agent (if needed)
  → go-reviewer agent (if Go files)
  → Iterate until LGTM
```

**2. Pre-User-Prompt → Suggests Skill**
```bash
hooks/pre-user-prompt/task-complexity-check.sh
     ↓
If complex keywords detected:
  SUGGESTION: /auto-review-loop
     ↓
User or Claude invokes skill
```

### Hooks → Agents (Direct)

**1. Security Hook → security-reviewer Agent**
```bash
hooks/pre-commit/security-check.sh
     ↓
If API changes detected:
  TRIGGER: security-reviewer
     ↓
Claude invokes:
  Task(subagent_type="security-reviewer", ...)
```

**2. Agent Router → Multiple Agents**
```bash
hooks/pre-user-prompt/agent-router.sh
     ↓
Analyzes task keywords:
  Recommends: architect, security-reviewer, database-reviewer
     ↓
Claude invokes agents directly:
  Task(subagent_type="architect", ...)
  Task(subagent_type="security-reviewer", ...)
  Task(subagent_type="database-reviewer", ...)
```

---

## Current Routing Summary

### What Hooks Analyze

| Hook | Analyzes | Routes To | Type |
|------|----------|-----------|------|
| **agent-router.sh** | Task keywords | Agents (direct) | Pre-user-prompt |
| **task-complexity-check.sh** | Task keywords | auto-review-loop skill | Pre-user-prompt |
| **complexity-assessment.sh** | Git diff patterns | auto-review-loop skill | Pre-task |
| **security-check.sh** | Git diff patterns | Security review trigger | Pre-commit |
| **schema-validation.sh** | Schema files | Validation trigger | Pre-commit |
| **test-coverage.sh** | Coverage % | TDD reminder | Pre-commit |

### Gaps (Not Currently Analyzed)

**Skills NOT automatically routed:**
- ❌ ddd-patterns
- ❌ event-driven-patterns
- ❌ gitops-patterns
- ❌ outbox-core-patterns
- ❌ persistence-patterns
- ❌ schema-registry
- ❌ service-creation

**These require manual invocation:** `/skill-name`

---

## Should We Add Skill Routing?

### Option 1: Extend agent-router.sh to Include Skills

```bash
# Add to agent-router.sh

# Skill routing
SKILLS=()

if echo "$PROMPT_LOWER" | grep -qE "(create service|new service|scaffold service)"; then
    SKILLS+=("service-creation")
fi

if echo "$PROMPT_LOWER" | grep -qE "(new aggregate|add aggregate|domain model)"; then
    SKILLS+=("ddd-patterns")
fi

if echo "$PROMPT_LOWER" | grep -qE "(kafka|event|publish|consume)"; then
    SKILLS+=("event-driven-patterns")
fi

if echo "$PROMPT_LOWER" | grep -qE "(deploy|helm|argocd|gitops)"; then
    SKILLS+=("gitops-patterns")
fi

# Output
echo "📋 Recommended Skills:"
for skill in "${SKILLS[@]}"; do
    echo "  • /skill"
done
```

### Option 2: Separate skill-router.sh Hook

Create dedicated skill routing hook:

```bash
hooks/pre-user-prompt/skill-router.sh
→ Analyzes task for skill patterns
→ Recommends appropriate skills
→ Claude invokes with /skill-name
```

### Option 3: Combined Intelligence Router

Single hook routes to both agents AND skills:

```bash
hooks/pre-user-prompt/intelligence-router.sh
→ Analyzes task
→ Recommends agents (for reviews)
→ Recommends skills (for workflows)
→ Suggests orchestration
```

---

## Recommendation: Add Skill Routing

**Why:**
- ✅ Complete automation of team patterns
- ✅ Enforce consistency across engineers
- ✅ Reduce manual skill discovery
- ✅ Faster onboarding

**What to Add:**
```
hooks/pre-user-prompt/skill-router.sh (new)
→ Routes to team skills

OR

Extend agent-router.sh to include skills
```

**Example Output:**
```
User: "Create new payment microservice"
     ↓
Router Output:
📋 Recommended Skills:
  • /service-creation
      → Scaffolds Spring Boot service structure

📋 Recommended Agents:
  • architect
      → Review service architecture after creation
  • security-reviewer
      → Review payment-specific security
```

---

## Best Practices

### 1. Start with Skill for Complex Tasks
```
Task: "Implement feature X"
First: Check if skill exists (/auto-review-loop, /ddd-patterns)
Then: Let skill orchestrate agents
```

### 2. Use Agents for Quick Reviews
```
Task: "Is this secure?"
Direct: Task(subagent_type="security-reviewer", ...)
```

### 3. Layer Agent Reviews
```
Task: "Review PR"
Parallel:
  - code-reviewer
  - security-reviewer
  - go-reviewer
```

### 4. Create Custom Skills for Repeated Workflows
```
Team has repeated pattern?
→ Create skill to encode it
→ Skill wraps agents
→ Team uses /skill-name
```

### 5. Let Hooks Route Automatically
```
Don't manually decide agent vs skill
→ Let hooks analyze task
→ Follow recommendations
→ Trust the routing logic
```

---

## Examples: Agent vs Skill Decisions

### Example 1: Security Audit

**Task:** "Audit authentication implementation"

**Decision:**
```
Option A: Agent (security-reviewer)
→ Quick security scan
→ Returns vulnerability report
→ 30 seconds
✅ CHOOSE THIS

Option B: Skill (hypothetical /security-audit)
→ Security scan + fix issues + re-scan + tests
→ Full audit workflow
→ 5 minutes
❌ OVERKILL
```

**Answer: Use Agent** (focused, fast)

---

### Example 2: Complex Feature

**Task:** "Implement payment processing saga"

**Decision:**
```
Option A: Agents (architect + security-reviewer + code-reviewer)
→ Multiple agents, manual orchestration
→ User must manage sequence
→ Risk missing steps
❌ MANUAL

Option B: Skill (/auto-review-loop)
→ Auto-orchestrates agents
→ Iterates until LGTM
→ Runs tests automatically
✅ CHOOSE THIS
```

**Answer: Use Skill** (complex workflow)

---

### Example 3: New Service

**Task:** "Create inventory microservice"

**Decision:**
```
Option A: Manual + Agents
→ User creates structure
→ Agents review after
→ Inconsistent with team patterns
❌ INCONSISTENT

Option B: Skill (/service-creation)
→ Scaffolds standard structure
→ Applies team patterns
→ Consistent across team
✅ CHOOSE THIS
```

**Answer: Use Skill** (team pattern)

---

### Example 4: Go Code Review

**Task:** "Review this Go function"

**Decision:**
```
Option A: Agent (go-reviewer)
→ Direct review
→ Fast feedback
→ 30 seconds
✅ CHOOSE THIS

Option B: Skill (hypothetical /go-review-workflow)
→ Review + fix + re-review + tests
→ Multi-step process
→ 3 minutes
❌ OVERKILL
```

**Answer: Use Agent** (simple review)

---

## Future: Unified Intelligence Router

**Vision:** Single hook that routes to agents, skills, or both

```bash
hooks/pre-user-prompt/intelligence-router.sh

User: "Implement OAuth2 with PostgreSQL"
     ↓
Router Analyzes:
  Complexity: High (score 8)
  Keywords: auth, database, implement
     ↓
Recommends:
  SKILLS:
    • /auto-review-loop (high complexity)

  AGENTS (within auto-review-loop):
    • architect (design)
    • security-reviewer (auth)
    • database-reviewer (PostgreSQL)
     ↓
Orchestration:
  1. architect → Design OAuth2 + DB schema
  2. /auto-review-loop implement design
     → code-reviewer
     → security-reviewer
     → database-reviewer
     → Iterate until LGTM
  3. Run tests
  4. Success
```

---

## Summary

### Agent vs Skill

| Scenario | Use | Example |
|----------|-----|---------|
| Quick review | Agent | "Is this secure?" |
| Specialized analysis | Agent | "Review Go concurrency" |
| Complex workflow | Skill | "Implement feature X" |
| Team pattern | Skill | "Create new service" |
| High complexity | Skill | Complexity score ≥ 5 |
| Multi-step process | Skill | Code → Review → Fix → Test |

### Current Routing

✅ **Agents:** Routed by `agent-router.sh`
⚠️ **Skills:** Only auto-review-loop routed (by complexity hooks)
❌ **Other Skills:** Manual invocation only

### Should Add

🚀 **Skill routing** to agent-router.sh or separate hook
→ Auto-recommend service-creation, ddd-patterns, etc.
→ Complete automation of team patterns

---

**Last Updated:** 2026-05-18
**Routing Version:** 1.0
