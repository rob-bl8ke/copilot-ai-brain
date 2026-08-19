# Specialized Agents Reference

This document describes the 13 specialized agents available through the `everything-claude-code` plugin.

## Overview

Agents are autonomous subprocesses that handle specific engineering tasks. They run independently with their own context and tools, then return results to the main session.

### When to Use Agents

- **Complex tasks** requiring multiple steps
- **Specialized reviews** (security, architecture, language-specific)
- **Build/test operations** that need isolation
- **Iterative workflows** (review → fix → review)

### How to Invoke

```bash
# Via Task tool
Task(subagent_type="everything-claude-code:code-reviewer")

# Via skills that wrap agents
/auto-review-loop      # Uses code-reviewer internally
/security-review       # Uses security-reviewer
/go-review            # Uses go-reviewer
```

---

## Code Quality Agents

### 1. code-reviewer (Opus)

**Purpose:** Expert code review for quality, security, and maintainability

**When to Use:**
- ✅ After writing/modifying any code
- ✅ Before committing changes
- ✅ During auto-review-loop iterations

**What It Checks:**
- Code readability and naming
- Function size (>50 lines flagged)
- File size (>800 lines flagged)
- Nesting depth (>4 levels flagged)
- Error handling completeness
- Test coverage adequacy
- Security vulnerabilities
- Hardcoded secrets
- Performance issues
- Algorithm complexity

**Output Format:**
```
Critical Issues (must fix):
  • [file.java:42] SQL injection risk in query string concatenation
  • [auth.java:15] Hardcoded API key detected

Warnings (should fix):
  • [service.java:100] Function too large (120 lines, max 50)
  • [controller.java:55] Missing error handling for API call

Suggestions (consider):
  • [util.java:30] Consider extracting duplicate logic into helper
  • [model.java:10] Add JSR-303 validation annotations
```

**Example Usage:**
```bash
# After implementing feature
Task(
  subagent_type="everything-claude-code:code-reviewer",
  prompt="Review the authentication changes in the current branch"
)
```

---

### 2. refactor-cleaner

**Purpose:** Dead code cleanup and consolidation

**When to Use:**
- ✅ After major refactoring
- ✅ Before releases
- ✅ During technical debt sprints
- ✅ When codebase feels cluttered

**What It Does:**
- Identifies unused imports, functions, variables
- Finds duplicate code blocks
- Detects orphaned files
- Removes commented-out code
- Consolidates similar logic

**Tools Used:**
- `knip` - Finds unused code in TypeScript/JavaScript
- `depcheck` - Detects unused dependencies
- `ts-prune` - Finds unused exports

**Example Usage:**
```bash
Task(
  subagent_type="everything-claude-code:refactor-cleaner",
  prompt="Clean up unused code in the user service module"
)
```

---

### 3. doc-updater

**Purpose:** Documentation and codemap maintenance

**When to Use:**
- ✅ After architectural changes
- ✅ When adding new modules
- ✅ Before team handoffs
- ✅ During onboarding prep

**What It Updates:**
- Codemaps (docs/CODEMAPS/*)
- README files
- Architecture diagrams
- API documentation
- Setup guides

**Commands Run:**
- `/update-codemaps` - Regenerates codebase maps
- `/update-docs` - Refreshes documentation

**Example Usage:**
```bash
Task(
  subagent_type="everything-claude-code:doc-updater",
  prompt="Update documentation after adding payment service"
)
```

---

## Security Agent

### 4. security-reviewer (Opus)

**Purpose:** Vulnerability detection and remediation

**When to Use (PROACTIVE):**
- ✅ After adding API endpoints
- ✅ After authentication/authorization code
- ✅ After handling user input
- ✅ After database queries
- ✅ After external API integrations
- ✅ Before production deploys

**What It Checks:**

**OWASP Top 10:**
- Injection (SQL, NoSQL, Command, LDAP)
- Broken Authentication
- Sensitive Data Exposure
- XML External Entities (XXE)
- Broken Access Control
- Security Misconfiguration
- Cross-Site Scripting (XSS)
- Insecure Deserialization
- Vulnerable Dependencies
- Insufficient Logging

**Specific Vulnerabilities:**
- Hardcoded credentials (API keys, passwords, tokens)
- SQL injection (string concatenation in queries)
- Path traversal (user-controlled file paths)
- SSRF (Server-Side Request Forgery)
- CSRF (Cross-Site Request Forgery)
- Insecure crypto (MD5, SHA1, weak algorithms)
- Missing input validation
- Authentication bypasses

**Tools Used:**
```bash
npm audit                    # Vulnerable dependencies
eslint-plugin-security       # Static security analysis
trufflehog                   # Secrets in git history
semgrep                      # Pattern-based scanning
```

**Output Format:**
```
CRITICAL VULNERABILITIES:
  🚨 [auth.java:23] Hardcoded AWS secret key
  🚨 [api.java:45] SQL injection via string concatenation

HIGH RISK:
  ⚠️  [service.java:67] Missing authentication check
  ⚠️  [controller.java:89] User input not validated

MEDIUM RISK:
  ℹ️  [pom.xml:15] Dependency spring-boot 2.5.0 has CVE-2021-12345

RECOMMENDATIONS:
  • Use parameterized queries for all SQL
  • Implement input validation with JSR-303
  • Update vulnerable dependencies
  • Add @PreAuthorize annotations
```

**Example Usage:**
```bash
# Triggered by pre-commit hook
Task(
  subagent_type="everything-claude-code:security-reviewer",
  prompt="Review security of new payment processing endpoint"
)
```

---

## Architecture & Planning Agents

### 5. architect (Opus)

**Purpose:** System design, scalability, technical decisions

**When to Use (PROACTIVE):**
- ✅ Planning new features
- ✅ Refactoring large systems
- ✅ Making architectural decisions
- ✅ Evaluating trade-offs
- ✅ Designing integrations

**What It Provides:**
- High-level architecture diagrams
- Component responsibilities
- Data models and flows
- API contracts
- Integration patterns
- Trade-off analysis
- Scalability recommendations

**Review Process:**
1. **Current State Analysis**
   - Existing architecture patterns
   - Technical debt assessment
   - Scalability limitations

2. **Requirements Gathering**
   - Functional requirements
   - Non-functional requirements (performance, security)
   - Integration points

3. **Design Proposal**
   - Architecture diagram
   - Component breakdown
   - Data models
   - API contracts

4. **Trade-Off Analysis**
   - Pros/cons of each approach
   - Alternatives considered
   - Final recommendation

**Architectural Principles Enforced:**
- Modularity & Separation of Concerns
- Domain-Driven Design
- SOLID principles
- Event-driven architecture
- Microservices patterns

**Example Usage:**
```bash
Task(
  subagent_type="everything-claude-code:architect",
  prompt="Design architecture for real-time notification system with Kafka"
)
```

---

### 6. planner

**Purpose:** Implementation planning for complex features

**When to Use:**
- ✅ Before starting complex features
- ✅ When task requires multiple steps
- ✅ When dependencies are unclear
- ✅ When approach is uncertain

**What It Provides:**
- Step-by-step implementation plan
- File structure recommendations
- Dependency order
- Testing strategy
- Risk assessment

**Example Usage:**
```bash
Task(
  subagent_type="everything-claude-code:planner",
  prompt="Plan implementation of OAuth2 authentication with role-based access"
)
```

---

## Build & Error Resolution Agents

### 7. build-error-resolver

**Purpose:** TypeScript/build error resolution with minimal diffs

**When to Use:**
- ✅ Build failures
- ✅ Type errors
- ✅ Compilation issues
- ✅ After dependency updates

**Focus:** Get build green quickly with surgical fixes

**What It Fixes:**
- Type errors
- Import errors
- Configuration issues
- Dependency conflicts

**Example Usage:**
```bash
Task(
  subagent_type="everything-claude-code:build-error-resolver",
  prompt="Fix TypeScript build errors after upgrading to React 18"
)
```

---

### 8. go-build-resolver

**Purpose:** Go build, vet, and linter error resolution

**When to Use:**
- ✅ Go build failures
- ✅ `go vet` warnings
- ✅ Linter issues (golangci-lint)
- ✅ Module dependency errors

**Focus:** Minimal, idiomatic fixes

**What It Fixes:**
- Build errors
- Import cycles
- Unused variables
- Shadowed variables
- Printf format issues
- Mutex copy issues
- Unreachable code

**Example Usage:**
```bash
Task(
  subagent_type="everything-claude-code:go-build-resolver",
  prompt="Fix go vet warnings in payment service"
)
```

---

## Language-Specific Reviewers

### 9. go-reviewer

**Purpose:** Comprehensive Go code review

**When to Use:**
- ✅ All Go code changes (MANDATORY)
- ✅ Before merging Go PRs
- ✅ During code reviews

**What It Checks:**

**Idiomatic Go:**
- Package naming (lowercase, single word)
- Interface naming (Reader, Writer, Closer)
- Error handling patterns
- Pointer vs value receivers
- Struct embedding
- Zero values

**Concurrency:**
- Race conditions
- Deadlocks
- Goroutine leaks
- Channel misuse
- Mutex usage
- Context propagation

**Error Handling:**
- Error wrapping (fmt.Errorf with %w)
- Error types vs values
- Panic usage (only for unrecoverable errors)

**Performance:**
- Unnecessary allocations
- String concatenation (use strings.Builder)
- Map vs slice choice
- Defer placement

**Example Usage:**
```bash
# Via skill
/go-review

# Via Task tool
Task(
  subagent_type="everything-claude-code:go-reviewer",
  prompt="Review concurrency patterns in worker pool implementation"
)
```

---

### 10. python-reviewer

**Purpose:** Comprehensive Python code review

**When to Use:**
- ✅ All Python code changes (MANDATORY)
- ✅ Before merging Python PRs
- ✅ During code reviews

**What It Checks:**

**PEP 8 Compliance:**
- Indentation (4 spaces)
- Line length (79 chars)
- Naming conventions
- Import ordering

**Pythonic Idioms:**
- List comprehensions
- Context managers (with statements)
- Generators
- Decorators
- Property usage

**Type Hints:**
- Function signatures
- Return types
- Variable annotations
- Generic types

**Security:**
- SQL injection (use parameterized queries)
- Command injection
- Path traversal
- Pickle deserialization
- eval() usage

**Performance:**
- List vs generator
- String concatenation
- Loop optimization
- Caching opportunities

**Example Usage:**
```bash
# Via skill
/python-review

# Via Task tool
Task(
  subagent_type="everything-claude-code:python-reviewer",
  prompt="Review Django API views for security and performance"
)
```

---

## Database Agent

### 11. database-reviewer

**Purpose:** PostgreSQL query optimization, schema design, security

**When to Use:**
- ✅ Writing SQL queries
- ✅ Creating migrations
- ✅ Designing schemas
- ✅ Performance troubleshooting
- ✅ Using Supabase

**What It Checks:**

**Query Optimization:**
- Index usage (EXPLAIN ANALYZE)
- N+1 query problems
- Missing joins
- Inefficient WHERE clauses
- SELECT * abuse

**Schema Design:**
- Normalization (3NF)
- Primary keys
- Foreign key constraints
- Index strategies
- Partitioning needs

**Security:**
- SQL injection prevention
- Row-Level Security (RLS) policies
- Permission grants
- Connection pooling

**Supabase Best Practices:**
- RLS policies
- Edge Functions
- Real-time subscriptions
- Storage buckets

**Example Usage:**
```bash
Task(
  subagent_type="everything-claude-code:database-reviewer",
  prompt="Review customer query performance and suggest indexes"
)
```

---

## Testing Agents

### 12. tdd-guide

**Purpose:** Test-Driven Development enforcement

**When to Use:**
- ✅ New features (MANDATORY)
- ✅ Bug fixes
- ✅ Refactoring

**Workflow Enforced:**
```
1. Write failing test
2. Implement minimal code to pass
3. Refactor
4. Ensure 80%+ coverage
```

**Test Types:**
- Unit tests
- Integration tests
- E2E tests (critical paths)

**Coverage Requirements:**
- Minimum: 80%
- Target: 90%+
- Critical paths: 100%

**Example Usage:**
```bash
# Via skill
/tdd implement user registration

# Via Task tool
Task(
  subagent_type="everything-claude-code:tdd-guide",
  prompt="Write tests first for payment processing saga"
)
```

---

### 13. e2e-runner

**Purpose:** End-to-end testing with browser automation

**When to Use:**
- ✅ Testing critical user flows
- ✅ Regression testing
- ✅ Visual regression
- ✅ Integration verification

**What It Does:**
- Generates E2E test journeys
- Runs tests (Vercel Agent Browser or Playwright)
- Captures screenshots
- Records videos
- Generates traces
- Uploads artifacts
- Quarantines flaky tests

**Critical User Flows:**
- Login/logout
- Registration
- Payment processing
- Form submissions
- Navigation paths

**Example Usage:**
```bash
# Via skill
/e2e test the checkout flow

# Via Task tool
Task(
  subagent_type="everything-claude-code:e2e-runner",
  prompt="Generate and run E2E tests for invoice submission flow"
)
```

---

## Agent Workflows

### Auto-Review-Loop (Complex Tasks)

When complexity score ≥5, this workflow triggers automatically:

```
1. IMPLEMENT
   ↓
2. CODE REVIEW (code-reviewer agent)
   ↓
   Issues found?
   ├─ Yes → FIX → back to step 2 (max 3 iterations)
   └─ No (LGTM) → step 3
   ↓
3. RUN TESTS
   ↓
   Pass?
   ├─ Yes → SUCCESS
   └─ No → back to step 1
```

**Agents Used:**
- `code-reviewer` - Quality and security review
- `security-reviewer` - If API/auth changes detected
- `go-reviewer` or `python-reviewer` - Language-specific review
- `build-error-resolver` - If build breaks

---

### Security Review Flow

When API/auth/SQL/external API changes detected:

```
1. DETECT CHANGE (pre-commit hook)
   ↓
2. SECURITY REVIEW (security-reviewer agent)
   ↓
3. REPORT VULNERABILITIES
   ↓
4. FIX ISSUES
   ↓
5. RE-REVIEW
   ↓
6. VERIFY FIX
```

---

### Go Development Flow

For all Go code changes:

```
1. WRITE CODE
   ↓
2. GO BUILD REVIEW (go-build-resolver)
   ↓
3. GO CODE REVIEW (go-reviewer)
   ↓
4. IDIOMATIC CHECKS
   ↓
5. CONCURRENCY REVIEW
   ↓
6. RUN TESTS
```

---

## Configuration

### Enabling Agents

Agents are automatically available when `everything-claude-code` plugin is enabled:

```json
{
  "enabledPlugins": {
    "everything-claude-code@everything-claude-code": true
  }
}
```

### Agent Models

Most agents use **Opus** for high-quality analysis:
- `code-reviewer` - Opus
- `security-reviewer` - Opus
- `architect` - Opus
- Others - Configurable

### Parallel Agent Execution

Run multiple agents in parallel for faster feedback:

```bash
# Single message with multiple Task calls
Task(subagent_type="everything-claude-code:code-reviewer", ...)
Task(subagent_type="everything-claude-code:security-reviewer", ...)
Task(subagent_type="everything-claude-code:go-reviewer", ...)
```

---

## Best Practices

### 1. Use Proactive Agents

Don't wait for issues - invoke agents immediately after changes:

```bash
# After implementing feature
/auto-review-loop  # Triggers code-reviewer automatically

# After API endpoint
Task(subagent_type="everything-claude-code:security-reviewer", ...)

# After Go changes
/go-review
```

### 2. Layer Multiple Reviews

Complex changes benefit from multiple specialized reviews:

```bash
1. code-reviewer       # General quality
2. security-reviewer   # Vulnerabilities
3. go-reviewer         # Language-specific
4. database-reviewer   # Query optimization
```

### 3. Trust Agent Output

Agents are specialized and thorough - their feedback is authoritative.

### 4. Iterate Until LGTM

Don't skip review feedback - iterate until agents approve.

### 5. Document Agent Decisions

When agents suggest trade-offs, document the decision:

```java
// Agent: architect
// Decision: Use outbox pattern for consistency
// Trade-off: Slightly more complex, but guarantees eventual consistency
```

---

## Troubleshooting

### Agent Times Out
- Reduce scope (review specific files instead of entire repo)
- Use lighter model (change from Opus to Sonnet)

### Agent Gives Generic Advice
- Provide more context in prompt
- Point to specific files/functions
- Include relevant code snippets

### Agent Misses Issues
- Run multiple specialized agents (layer reviews)
- Manually review agent output
- Report false negatives to improve prompts

### Agent Over-Flags
- Review critical issues first, ignore suggestions
- Tune agent sensitivity in prompt
- Create team-specific agent configs

---

## Integration with Team Config

Agents integrate with team hooks and skills:

```bash
# Hooks trigger agents
hooks/pre-commit/security-check.sh
→ Detects API changes
→ Triggers security-reviewer agent

# Skills wrap agents
skills/auto-review-loop/SKILL.md
→ Uses code-reviewer agent
→ Iterates until LGTM

skills/go-review/SKILL.md
→ Uses go-reviewer agent
→ Checks idiomatic patterns
```

---

## Metrics

Track agent effectiveness:

| Metric | Target | Purpose |
|--------|--------|---------|
| Issues caught pre-commit | >80% | Prevent bugs |
| False positive rate | <20% | Agent accuracy |
| Time to LGTM | <3 iterations | Efficiency |
| Security vulnerabilities found | Track trend | Risk reduction |
| Build failures prevented | >90% | Stability |

---

## Support

- **Agent Documentation:** `/Users/cp364719/.claude/plugins/cache/everything-claude-code/`
- **Team Config:** `~/team-claude-config/`
- **Issues:** Report to engineering team or plugin maintainer

---

**Last Updated:** 2026-05-18
**Plugin Version:** everything-claude-code@1.2.0
