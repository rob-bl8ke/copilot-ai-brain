# Intelligent Agent Router

**Hook:** `hooks/pre-user-prompt/agent-router.sh`

Analyzes user requests and automatically recommends which specialized agents to invoke.

---

## How It Works

### 1. User Submits Task
```
User: "Implement OAuth2 authentication with PostgreSQL"
```

### 2. Hook Analyzes Keywords
```bash
🤖 Analyzing task for agent routing...

Detected patterns:
  • "authentication" → security-reviewer
  • "OAuth2" → security-reviewer
  • "PostgreSQL" → database-reviewer
```

### 3. Recommends Agents
```
📋 Recommended Agents:

  🗄️  database-reviewer
      → Query optimization, schema design, PostgreSQL
      → Use: Task(subagent_type="everything-claude-code:database-reviewer", ...)

  🔒 security-reviewer
      → OWASP Top 10, vulnerabilities, secrets detection
      → Use: Task(subagent_type="everything-claude-code:security-reviewer", ...)

💡 Tip: Claude should proactively invoke these agents
```

### 4. Claude Auto-Invokes (Proactive)
```
Claude sees recommendations → Spawns agents automatically
```

---

## Routing Rules

### Architecture & Planning

| Keywords | Agent | Reason |
|----------|-------|--------|
| design, architect, plan | `architect` | System design needed |
| complex, multi-step, distributed | `planner` | Implementation planning |
| refactor, restructure, redesign | `architect` | Architectural changes |

**Example:**
```
"Design a scalable microservices architecture"
→ architect, planner
```

---

### Security-Sensitive

| Keywords | Agent | Reason |
|----------|-------|--------|
| auth, authentication, login | `security-reviewer` | Authentication logic |
| password, token, jwt, oauth | `security-reviewer` | Credentials handling |
| payment, credit card, sensitive | `security-reviewer` | Sensitive data |
| encrypt, decrypt, api key, secret | `security-reviewer` | Cryptography |

**Example:**
```
"Implement payment processing endpoint"
→ security-reviewer
```

---

### Database Operations

| Keywords | Agent | Reason |
|----------|-------|--------|
| database, sql, query | `database-reviewer` | Query optimization |
| migration, schema, index | `database-reviewer` | Schema design |
| postgres, supabase | `database-reviewer` | PostgreSQL-specific |

**Example:**
```
"Create customer table with indexes"
→ database-reviewer
```

---

### Language-Specific

| Keywords | Agent | Reason |
|----------|-------|--------|
| go, golang, goroutine, channel | `go-reviewer` | Go code review |
| python, django, flask, pytest | `python-reviewer` | Python code review |

**Example:**
```
"Optimize Go concurrent worker pool"
→ go-reviewer, go-build-resolver (if errors)
```

---

### Testing

| Keywords | Agent | Reason |
|----------|-------|--------|
| test, tdd, unit test, coverage | `tdd-guide` | Test-first development |
| e2e, end-to-end, browser test | `e2e-runner` | Browser automation |

**Example:**
```
"Write tests for checkout flow"
→ tdd-guide, e2e-runner
```

---

### Code Quality

| Keywords | Agent | Reason |
|----------|-------|--------|
| refactor, clean up, dead code | `refactor-cleaner` | Code cleanup |
| document, readme, codemap | `doc-updater` | Documentation |

**Example:**
```
"Clean up unused imports and dead code"
→ refactor-cleaner
```

---

### Build & Errors

| Keywords | Agent | Reason |
|----------|-------|--------|
| build error, type error | `build-error-resolver` | TypeScript/build fixes |
| go vet, go build, golangci-lint | `go-build-resolver` | Go build fixes |

**Example:**
```
"Fix TypeScript compilation errors"
→ build-error-resolver
```

---

## Orchestration Strategies

### Sequential (Planning First)

When `architect` or `planner` detected:

```
1. architect/planner → Design system
     ↓
2. security-reviewer → Review security (if needed)
     ↓
3. Implement code
     ↓
4. go-reviewer/python-reviewer → Language review
     ↓
5. tdd-guide → Ensure tests
```

**Example:**
```
"Design and implement payment saga"

Orchestration:
  1. architect → Design saga pattern
  2. security-reviewer → Review payment security
  3. Implement saga
  4. go-reviewer → Review Go implementation
  5. tdd-guide → Add integration tests
```

---

### Parallel (Fast Feedback)

When no planning agents:

```
       ┌─ security-reviewer
       │
Start ─┼─ database-reviewer  → Aggregate Results
       │
       └─ go-reviewer
```

**Example:**
```
"Fix authentication bug"

Orchestration:
  Parallel:
    - security-reviewer (auth logic)
    - go-reviewer (code quality)
  → Combine feedback → Fix
```

---

## Real-World Examples

### Example 1: OAuth Implementation

**Input:**
```
"Implement OAuth2 authentication with role-based access control"
```

**Router Output:**
```
🤖 Analyzing task for agent routing...

📋 Recommended Agents:

  🏗️  architect
      → System design, scalability, architectural decisions

  🔒 security-reviewer
      → OWASP Top 10, vulnerabilities, secrets detection

  ✅ tdd-guide
      → Test-Driven Development, write tests first

🔀 Orchestration Suggestion:

  Sequential (Planning First):
    1. architect → Design system
    2. security-reviewer → Review security
    3. Implement code
    4. tdd-guide → Ensure test coverage
```

---

### Example 2: Database Optimization

**Input:**
```
"Optimize slow customer query and add indexes"
```

**Router Output:**
```
📋 Recommended Agents:

  🗄️  database-reviewer
      → Query optimization, schema design, PostgreSQL

💡 Tip: Claude should proactively invoke these agents
```

---

### Example 3: Go Concurrency Bug

**Input:**
```
"Fix race condition in Go worker pool and ensure proper goroutine cleanup"
```

**Router Output:**
```
📋 Recommended Agents:

  🐹 go-reviewer
      → Idiomatic Go, concurrency, error handling

  🧹 refactor-cleaner
      → Dead code cleanup, duplicate removal

🔀 Orchestration Suggestion:

  Parallel (Fast Feedback):
    Run all agents simultaneously after implementation
```

---

### Example 4: Complex Saga

**Input:**
```
"Design distributed payment processing saga with event sourcing and Kafka"
```

**Router Output:**
```
📋 Recommended Agents:

  🏗️  architect
      → System design, scalability, architectural decisions

  📝 planner
      → Implementation planning for complex features

  🗄️  database-reviewer
      → Query optimization, schema design, PostgreSQL

  🔒 security-reviewer
      → OWASP Top 10, vulnerabilities, secrets detection

🔀 Orchestration Suggestion:

  Sequential (Planning First):
    1. architect/planner → Design system
    2. security-reviewer → Review security
    3. Implement code
    4. tdd-guide → Ensure test coverage
```

---

## Testing the Router

### Manual Test

```bash
cd ~/team-claude-config

# Test various prompts
./hooks/pre-user-prompt/agent-router.sh "Implement payment API"
./hooks/pre-user-prompt/agent-router.sh "Fix Go build errors"
./hooks/pre-user-prompt/agent-router.sh "Design scalable architecture"
./hooks/pre-user-prompt/agent-router.sh "Write E2E tests for checkout"
```

### Expected Behavior

**Security Task:**
```bash
$ ./hooks/pre-user-prompt/agent-router.sh "Add authentication"

📋 Recommended Agents:
  🔒 security-reviewer
```

**Database Task:**
```bash
$ ./hooks/pre-user-prompt/agent-router.sh "Create migration"

📋 Recommended Agents:
  🗄️  database-reviewer
```

**Go Task:**
```bash
$ ./hooks/pre-user-prompt/agent-router.sh "Fix goroutine leak"

📋 Recommended Agents:
  🐹 go-reviewer
```

---

## Integration with Claude

### Automatic Invocation

Claude Code reads hook output and should proactively invoke recommended agents:

```
User: "Implement OAuth2"
     ↓
Hook: Recommends security-reviewer, architect
     ↓
Claude: Sees recommendations
     ↓
Claude: Auto-invokes agents
     ↓
Task(subagent_type="everything-claude-code:architect", ...)
Task(subagent_type="everything-claude-code:security-reviewer", ...)
```

### Manual Override

User can always invoke agents directly:

```
User: "Implement OAuth2 but skip architecture review"
     ↓
Claude: Skips architect, invokes only security-reviewer
```

---

## Customization

### Add Custom Keywords

Edit `hooks/pre-user-prompt/agent-router.sh`:

```bash
# Add your domain-specific keywords
if echo "$PROMPT_LOWER" | grep -qE "(your-keyword|your-pattern)"; then
    AGENTS+=("your-preferred-agent")
fi
```

**Example: Add Custom Business Logic Keywords**
```bash
# Business logic patterns
if echo "$PROMPT_LOWER" | grep -qE "(loan approval|credit check|underwriting)"; then
    AGENTS+=("architect")
    AGENTS+=("security-reviewer")
    AGENTS+=("database-reviewer")
fi
```

---

### Adjust Agent Priority

Reorder recommendations by priority:

```bash
# High priority agents first
PRIORITY_AGENTS=()
STANDARD_AGENTS=()

# Security is always high priority
if [[ " ${AGENTS[@]} " =~ " security-reviewer " ]]; then
    PRIORITY_AGENTS+=("security-reviewer")
fi

# Then output in order
for agent in "${PRIORITY_AGENTS[@]}" "${STANDARD_AGENTS[@]}"; do
    # Display agent
done
```

---

## Limitations

### Current Limitations

1. **Keyword-Based Only**
   - No semantic understanding
   - Can miss context
   - May over-trigger on ambiguous terms

2. **No Multi-Language Detection**
   - Can't detect "Go and Python" → routes to both
   - May recommend conflicting agents

3. **No Complexity Scoring**
   - Doesn't integrate with complexity-assessment.sh
   - Parallel routing complexity check

4. **Static Rules**
   - No learning from past routing decisions
   - No feedback loop

### Future Enhancements

**Phase 2: Semantic Analysis**
- Use LLM to understand task intent
- Context-aware routing
- Better multi-language detection

**Phase 3: Learning System**
- Track which agents were useful
- Adjust routing rules based on outcomes
- Team-specific patterns

**Phase 4: Predictive Routing**
- Predict agent needs before implementation
- Suggest agent combinations
- Estimate agent execution time

---

## Metrics

Track router effectiveness:

| Metric | Target | How to Measure |
|--------|--------|----------------|
| Routing accuracy | >80% | Did recommended agents find issues? |
| False positives | <20% | Were agents unnecessary? |
| Coverage | >90% | Did router catch all needed agents? |
| User satisfaction | >4/5 | Post-task survey |

**Tracking:**
```bash
# Log router recommendations
echo "Task: $USER_PROMPT" >> ~/claude-agent-router.log
echo "Agents: ${AGENTS[@]}" >> ~/claude-agent-router.log
echo "Timestamp: $(date)" >> ~/claude-agent-router.log
echo "---" >> ~/claude-agent-router.log
```

---

## Troubleshooting

### Router Not Triggering

**Check:**
1. Hook is executable: `ls -la hooks/pre-user-prompt/agent-router.sh`
2. Hook is in correct location: `~/team-claude-config/hooks/pre-user-prompt/`
3. Claude Code settings point to hooks directory

**Fix:**
```bash
chmod +x hooks/pre-user-prompt/agent-router.sh
```

---

### Wrong Agents Recommended

**Solutions:**
1. Refine keyword patterns in router
2. Add domain-specific keywords
3. Adjust orchestration logic
4. Report false positives to improve rules

---

### Too Many Agents

**Solutions:**
1. Increase keyword specificity
2. Add exclusion rules
3. Prioritize agents (show top 3)

**Example:**
```bash
# Only show top 3 agents
AGENTS=($(printf '%s\n' "${AGENTS[@]}" | head -3))
```

---

## FAQ

**Q: Does router automatically invoke agents?**
A: No, router **recommends** agents. Claude Code should read recommendations and proactively invoke them.

**Q: Can I disable router for specific tasks?**
A: Yes, router suggestions are just recommendations. Claude or user can ignore them.

**Q: How does router integrate with complexity assessment?**
A: They're independent. Complexity hook triggers auto-review-loop. Router suggests specialized agents.

**Q: Can router learn from past decisions?**
A: Not yet. Current version uses static rules. Learning system planned for Phase 3.

**Q: What if router recommends conflicting agents?**
A: Router shows all matches. Claude should select appropriate agents based on task context.

---

**Last Updated:** 2026-05-18
**Router Version:** 1.0
