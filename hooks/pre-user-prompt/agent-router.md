#!/bin/bash
# Pre-user-prompt hook: Intelligent agent routing based on task analysis
#
# Analyzes user's request and recommends appropriate agents to invoke
# Uses keyword matching and pattern detection to route to specialized agents

# Error handling
set -euo pipefail
trap 'echo "❌ Agent router hook failed at line $LINENO" >&2' ERR

# Logging setup
LOG_DIR="$HOME/.claude/hook-logs"
mkdir -p "$LOG_DIR" 2>/dev/null || true
LOG_FILE="$LOG_DIR/agent-router.log"
echo "$(date '+%Y-%m-%d %H:%M:%S') - Hook started" >> "$LOG_FILE" 2>/dev/null || true

# Track execution time
HOOK_START=$(date +%s%N 2>/dev/null || date +%s)

# Read user prompt from stdin (provided by Claude Code)
USER_PROMPT="${1:-}"

if [ -z "$USER_PROMPT" ]; then
    # No prompt provided, skip
    exit 0
fi

# Convert to lowercase for matching
PROMPT_LOWER=$(echo "$USER_PROMPT" | tr '[:upper:]' '[:lower:]')

# ============================================================================
# EARLY EXIT: Skip routing for simple queries that don't need agents
# ============================================================================
# Questions about code (not implementation tasks)
if echo "$PROMPT_LOWER" | grep -qE "^(what|where|how|why|explain|show|describe|list|tell me|can you)" && \
   ! echo "$PROMPT_LOWER" | grep -qE "(implement|create|add|build|write|fix|refactor|deploy)"; then
    exit 0
fi

# Very short prompts (< 10 chars) are unlikely to need routing
if [ ${#USER_PROMPT} -lt 10 ]; then
    exit 0
fi

# Conversational or meta prompts
if echo "$PROMPT_LOWER" | grep -qE "^(yes|no|ok|sure|thanks|continue|go ahead|looks good|lgtm|approved)"; then
    exit 0
fi

echo "🤖 Analyzing task for agent routing..."
echo ""

# Agent routing recommendations
AGENTS=()

# ============================================================================
# ARCHITECTURE & PLANNING
# ============================================================================
if echo "$PROMPT_LOWER" | grep -qE "(design|architect|plan|refactor|restructure|redesign|system design|scalability)"; then
    AGENTS+=("architect")
fi

if echo "$PROMPT_LOWER" | grep -qE "(complex|multi-step|large feature|major change|distributed|microservice)"; then
    AGENTS+=("planner")
fi

# ============================================================================
# SECURITY-SENSITIVE TASKS
# ============================================================================
if echo "$PROMPT_LOWER" | grep -qE "(auth|authentication|authorization|login|password|token|jwt|oauth|security|payment|credit card|sensitive|encrypt|decrypt|api key|secret)"; then
    AGENTS+=("security-reviewer")
fi

# ============================================================================
# DATABASE OPERATIONS
# ============================================================================
if echo "$PROMPT_LOWER" | grep -qE "(database|sql|query|migration|schema|index|postgres|supabase|table|column|optimize query)"; then
    AGENTS+=("database-reviewer")
fi

# ============================================================================
# LANGUAGE-SPECIFIC
# ============================================================================
if echo "$PROMPT_LOWER" | grep -qE "(go|golang|goroutine|channel|concurrency)"; then
    AGENTS+=("go-reviewer")
fi

if echo "$PROMPT_LOWER" | grep -qE "(python|django|flask|pytest|pip)"; then
    AGENTS+=("python-reviewer")
fi

# ============================================================================
# TESTING
# ============================================================================
if echo "$PROMPT_LOWER" | grep -qE "(test|tdd|unit test|integration test|coverage|e2e|end.to.end)"; then
    AGENTS+=("tdd-guide")
fi

if echo "$PROMPT_LOWER" | grep -qE "(e2e|end.to.end|browser test|user flow|playwright)"; then
    AGENTS+=("e2e-runner")
fi

# ============================================================================
# CODE QUALITY
# ============================================================================
if echo "$PROMPT_LOWER" | grep -qE "(refactor|clean up|remove unused|dead code|duplicate|consolidate)"; then
    AGENTS+=("refactor-cleaner")
fi

if echo "$PROMPT_LOWER" | grep -qE "(document|readme|codemap|update docs)"; then
    AGENTS+=("doc-updater")
fi

# ============================================================================
# BUILD & ERRORS
# ============================================================================
if echo "$PROMPT_LOWER" | grep -qE "(build error|compilation error|type error|typescript error|fix build)"; then
    AGENTS+=("build-error-resolver")
fi

if echo "$PROMPT_LOWER" | grep -qE "(go vet|go build|golangci-lint|go test fails)"; then
    AGENTS+=("go-build-resolver")
fi

# ============================================================================
# SKILL ROUTING
# ============================================================================
SKILLS=()

# Service creation
if echo "$PROMPT_LOWER" | grep -qE "(create.*service|new.*service|scaffold.*service|bootstrap.*service)"; then
    SKILLS+=("service-creation")
fi

# DDD patterns
if echo "$PROMPT_LOWER" | grep -qE "(aggregate|entity|value object|domain model|bounded context|ddd)"; then
    SKILLS+=("ddd-patterns")
fi

# Clean architecture & SOLID
if echo "$PROMPT_LOWER" | grep -qE "(clean architecture|solid|single responsibility|dependency inversion|layer|refactor.*architecture)"; then
    SKILLS+=("clean-architecture")
fi

# Event-driven patterns
if echo "$PROMPT_LOWER" | grep -qE "(kafka|event.*driven|publish.*event|consume.*event|event.*sourcing)"; then
    SKILLS+=("event-driven-patterns")
fi

# GitOps patterns
if echo "$PROMPT_LOWER" | grep -qE "(deploy|argocd|helm|gitops|kubernetes|k8s)"; then
    SKILLS+=("gitops-patterns")
fi

# Outbox pattern
if echo "$PROMPT_LOWER" | grep -qE "(outbox|transactional.*outbox|event.*publishing|eventual.*consistency)"; then
    SKILLS+=("outbox-core-patterns")
fi

# Persistence patterns
if echo "$PROMPT_LOWER" | grep -qE "(repository|jpa|hibernate|entity.*manager|data.*access)"; then
    SKILLS+=("persistence-patterns")
fi

# Schema registry
if echo "$PROMPT_LOWER" | grep -qE "(schema.*registry|avro.*schema|protobuf.*schema|schema.*validation)"; then
    SKILLS+=("schema-registry")
fi

# Flyway / Database migration patterns
if echo "$PROMPT_LOWER" | grep -qE "(flyway|migration|schema change|alter table|create table|database migration)"; then
    SKILLS+=("flyway-patterns")
fi

# CI/CD pipeline patterns
if echo "$PROMPT_LOWER" | grep -qE "(ci.cd|pipeline|github actions|workflow|deploy|build pipeline|jfrog)"; then
    SKILLS+=("ci-cd-pipeline")
fi

# Observability patterns
if echo "$PROMPT_LOWER" | grep -qE "(logging|tracing|metrics|observability|monitoring|alert|cloudwatch|mdc|correlation)"; then
    SKILLS+=("observability-patterns")
fi

# Spring Boot service patterns
if echo "$PROMPT_LOWER" | grep -qE "(exception handler|error handling|global exception|correlation id|health check|actuator|spring profile)"; then
    SKILLS+=("spring-boot-service-patterns")
fi

# Auto-review-loop for complex implementation
if echo "$PROMPT_LOWER" | grep -qE "(implement|add|create|write|code|develop|build)"; then
    # Check for complexity indicators
    if echo "$PROMPT_LOWER" | grep -qE "(complex|distributed|saga|microservice|multi-step|large)"; then
        SKILLS+=("auto-review-loop")
    fi
fi

# ============================================================================
# OUTPUT RECOMMENDATIONS
# ============================================================================
if [ ${#AGENTS[@]} -eq 0 ] && [ ${#SKILLS[@]} -eq 0 ]; then
    echo "✅ No specialized agents or skills needed for this task"
    echo ""
    exit 0
fi

# ============================================================================
# OUTPUT SKILLS
# ============================================================================
if [ ${#SKILLS[@]} -gt 0 ]; then
    echo "🎯 Recommended Skills:"
    echo ""

    # Remove duplicates
    SKILLS=($(printf '%s\n' "${SKILLS[@]}" | sort -u))

    for skill in "${SKILLS[@]}"; do
        case "$skill" in
            service-creation)
                echo "  🏗️  /service-creation"
                echo "      → Scaffold new Spring Boot microservice"
                echo "      → Standard structure, dependencies, configs"
                ;;
            ddd-patterns)
                echo "  🧩 /ddd-patterns"
                echo "      → Domain-Driven Design patterns"
                echo "      → Aggregate, entity, value object guidance"
                ;;
            event-driven-patterns)
                echo "  📨 /event-driven-patterns"
                echo "      → Kafka messaging patterns"
                echo "      → Producer, consumer, schema best practices"
                ;;
            gitops-patterns)
                echo "  🚀 /gitops-patterns"
                echo "      → ArgoCD/Helm deployment"
                echo "      → GitOps workflow, Kubernetes manifests"
                ;;
            outbox-core-patterns)
                echo "  📦 /outbox-core-patterns"
                echo "      → Transactional outbox pattern"
                echo "      → Unified DB + event publishing"
                ;;
            persistence-patterns)
                echo "  💾 /persistence-patterns"
                echo "      → JPA/Hibernate best practices"
                echo "      → Repository pattern, entity management"
                ;;
            schema-registry)
                echo "  📋 /schema-registry"
                echo "      → Offline schema validation"
                echo "      → Avro/Protobuf schema patterns"
                ;;
            auto-review-loop)
                echo "  🔄 /auto-review-loop"
                echo "      → Code → Review → Fix → Test cycle"
                echo "      → Iterative quality improvement"
                ;;
            clean-architecture)
                echo "  🏛️  /clean-architecture"
                echo "      → Clean architecture layers & SOLID principles"
                echo "      → Layer isolation, dependency rules"
                ;;
            flyway-patterns)
                echo "  🗃️  /flyway-patterns"
                echo "      → Database migration best practices"
                echo "      → Naming, backward-compatibility, Aurora PostgreSQL"
                ;;
            ci-cd-pipeline)
                echo "  ⚙️  /ci-cd-pipeline"
                echo "      → GitHub Actions, JFrog, ArgoCD pipeline"
                echo "      → Build, test, publish, deploy workflow"
                ;;
            observability-patterns)
                echo "  📡 /observability-patterns"
                echo "      → Structured logging, tracing, metrics"
                echo "      → MDC propagation, CloudWatch, Micrometer"
                ;;
            spring-boot-service-patterns)
                echo "  🍃 /spring-boot-service-patterns"
                echo "      → Exception handling, correlation IDs, health checks"
                echo "      → Standard service infrastructure patterns"
                ;;
        esac
        echo ""
    done
fi

# ============================================================================
# OUTPUT AGENTS
# ============================================================================
if [ ${#AGENTS[@]} -gt 0 ]; then
    echo "📋 Recommended Agents:"
    echo ""
fi

# Remove duplicates
AGENTS=($(printf '%s\n' "${AGENTS[@]}" | sort -u))

for agent in "${AGENTS[@]}"; do
    case "$agent" in
        architect)
            echo "  🏗️  architect"
            echo "      → System design, scalability, architectural decisions"
            echo "      → Use: Task(subagent_type=\"everything-claude-code:architect\", prompt=\"...\")"
            ;;
        planner)
            echo "  📝 planner"
            echo "      → Implementation planning for complex features"
            echo "      → Use: Task(subagent_type=\"everything-claude-code:planner\", prompt=\"...\")"
            ;;
        security-reviewer)
            echo "  🔒 security-reviewer"
            echo "      → OWASP Top 10, vulnerabilities, secrets detection"
            echo "      → Use: Task(subagent_type=\"everything-claude-code:security-reviewer\", prompt=\"...\")"
            ;;
        database-reviewer)
            echo "  🗄️  database-reviewer"
            echo "      → Query optimization, schema design, PostgreSQL"
            echo "      → Use: Task(subagent_type=\"everything-claude-code:database-reviewer\", prompt=\"...\")"
            ;;
        go-reviewer)
            echo "  🐹 go-reviewer"
            echo "      → Idiomatic Go, concurrency, error handling"
            echo "      → Use: Task(subagent_type=\"everything-claude-code:go-reviewer\", prompt=\"...\")"
            ;;
        python-reviewer)
            echo "  🐍 python-reviewer"
            echo "      → PEP 8, Pythonic idioms, type hints, security"
            echo "      → Use: Task(subagent_type=\"everything-claude-code:python-reviewer\", prompt=\"...\")"
            ;;
        tdd-guide)
            echo "  ✅ tdd-guide"
            echo "      → Test-Driven Development, write tests first"
            echo "      → Use: Task(subagent_type=\"everything-claude-code:tdd-guide\", prompt=\"...\")"
            ;;
        e2e-runner)
            echo "  🎭 e2e-runner"
            echo "      → End-to-end testing with Playwright"
            echo "      → Use: Task(subagent_type=\"everything-claude-code:e2e-runner\", prompt=\"...\")"
            ;;
        refactor-cleaner)
            echo "  🧹 refactor-cleaner"
            echo "      → Dead code cleanup, duplicate removal"
            echo "      → Use: Task(subagent_type=\"everything-claude-code:refactor-cleaner\", prompt=\"...\")"
            ;;
        doc-updater)
            echo "  📚 doc-updater"
            echo "      → Documentation and codemap updates"
            echo "      → Use: Task(subagent_type=\"everything-claude-code:doc-updater\", prompt=\"...\")"
            ;;
        build-error-resolver)
            echo "  🔨 build-error-resolver"
            echo "      → TypeScript/build error resolution"
            echo "      → Use: Task(subagent_type=\"everything-claude-code:build-error-resolver\", prompt=\"...\")"
            ;;
        go-build-resolver)
            echo "  🔧 go-build-resolver"
            echo "      → Go build/vet/lint error resolution"
            echo "      → Use: Task(subagent_type=\"everything-claude-code:go-build-resolver\", prompt=\"...\")"
            ;;
    esac
    echo ""
done

echo "💡 Tip: Claude should proactively invoke these agents based on task requirements"
echo ""

# Log execution time
HOOK_END=$(date +%s%N 2>/dev/null || date +%s)
if [ ${#HOOK_START} -gt 10 ] && [ ${#HOOK_END} -gt 10 ]; then
    DURATION_MS=$(( (HOOK_END - HOOK_START) / 1000000 ))
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Agent routing completed (${DURATION_MS}ms)" >> "$LOG_FILE" 2>/dev/null || true
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Agent routing completed" >> "$LOG_FILE" 2>/dev/null || true
fi

# ============================================================================
# ORCHESTRATION SUGGESTIONS
# ============================================================================
if [ ${#AGENTS[@]} -gt 1 ]; then
    echo "🔀 Orchestration Suggestion:"
    echo ""

    # Check for planning agents
    if [[ " ${AGENTS[@]} " =~ " architect " ]] || [[ " ${AGENTS[@]} " =~ " planner " ]]; then
        echo "  Sequential (Planning First):"
        echo "    1. architect/planner → Design system"

        # Security
        if [[ " ${AGENTS[@]} " =~ " security-reviewer " ]]; then
            echo "    2. security-reviewer → Review security"
        fi

        # Implementation
        echo "    3. Implement code"

        # Language-specific review
        if [[ " ${AGENTS[@]} " =~ " go-reviewer " ]]; then
            echo "    4. go-reviewer → Review Go code"
        elif [[ " ${AGENTS[@]} " =~ " python-reviewer " ]]; then
            echo "    4. python-reviewer → Review Python code"
        fi

        # Testing
        if [[ " ${AGENTS[@]} " =~ " tdd-guide " ]]; then
            echo "    5. tdd-guide → Ensure test coverage"
        fi

    else
        echo "  Parallel (Fast Feedback):"
        echo "    Run all agents simultaneously after implementation"
    fi

    echo ""
fi

exit 0
