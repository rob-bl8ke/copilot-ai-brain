#!/bin/bash
# Post-code hook: DDD compliance check

# This hook provides reminders about DDD patterns after code changes

# Error handling
set -euo pipefail
trap 'echo "❌ Domain review hook failed at line $LINENO" >&2' ERR

# Logging setup
LOG_DIR="$HOME/.claude/hook-logs"
mkdir -p "$LOG_DIR" 2>/dev/null || true
LOG_FILE="$LOG_DIR/domain-review.log"
echo "$(date '+%Y-%m-%d %H:%M:%S') - Hook started" >> "$LOG_FILE" 2>/dev/null || true

# Detect changed files from working tree (staged + unstaged + untracked)
CHANGED_FILES=$(git status --porcelain 2>/dev/null | awk '{print $NF}')

# Check for entity changes
if echo "$CHANGED_FILES" | grep -qE "(Entity\.java|Aggregate\.java|ValueObject\.java)"; then
    echo ""
    echo "HOOK: Domain model changes detected"
    echo "DDD Checklist:"
    echo "  ✓ Entities have identity and lifecycle"
    echo "  ✓ Value Objects are immutable"
    echo "  ✓ Aggregates enforce consistency boundaries"
    echo "  ✓ Domain events published for state changes"
    echo "  ✓ Business logic in domain model, not services"
    echo ""
fi

# Check for repository changes
if echo "$CHANGED_FILES" | grep -qE "Repository\.java"; then
    echo ""
    echo "HOOK: Repository changes detected"
    echo "DDD Repository Pattern:"
    echo "  ✓ Repositories work with aggregate roots only"
    echo "  ✓ Return domain objects, not JPA entities"
    echo "  ✓ Use specifications for complex queries"
    echo ""
fi

# Check for service changes
if echo "$CHANGED_FILES" | grep -qE "(Service\.java|UseCase\.java)"; then
    echo ""
    echo "HOOK: Application service changes detected"
    echo "Service Layer Guidelines:"
    echo "  ✓ Orchestrate use cases, don't contain business logic"
    echo "  ✓ Transaction boundaries at service level"
    echo "  ✓ Publish domain events via outbox-core"
    echo "  ✓ Handle cross-aggregate coordination"
    echo ""
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') - Hook completed successfully" >> "$LOG_FILE" 2>/dev/null || true
exit 0
