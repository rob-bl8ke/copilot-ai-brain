#!/bin/bash
# Pre-task hook: Assess task complexity and trigger auto-review-loop for complex changes

# This hook analyzes the complexity of a task based on multiple signals
# If complexity exceeds threshold, it enforces code review and testing via auto-review-loop

# Exit codes:
# 0 - Task assessed, continue normally
# 1 - Error in assessment

set -e

# Configuration
COMPLEXITY_THRESHOLD=5  # Trigger auto-review-loop if score >= threshold
MAX_FILES_SIMPLE=3      # More than this = complex
MAX_LINES_SIMPLE=200    # More than this = complex

# Complexity scoring
complexity_score=0
complexity_reasons=()

# Function to add complexity points
add_complexity() {
    local points=$1
    local reason=$2
    complexity_score=$((complexity_score + points))
    complexity_reasons+=("$reason")
}

echo "🔍 Assessing task complexity..."

# ============================================================================
# SIGNAL 1: Check git diff size (if in git context)
# ============================================================================
if git rev-parse --git-dir > /dev/null 2>&1; then
    # Check staged or unstaged changes
    if git diff --cached --quiet && git diff --quiet; then
        # No current changes, check last commit
        FILES_CHANGED=$(git diff HEAD~1..HEAD --name-only 2>/dev/null | wc -l | tr -d ' ')
        LINES_CHANGED=$(git diff HEAD~1..HEAD --shortstat 2>/dev/null | awk '{print $4+$6}' | tr -d ' ')
    else
        # Check current changes
        FILES_CHANGED=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
        LINES_CHANGED=$(git diff --cached --shortstat 2>/dev/null | awk '{print $4+$6}' | tr -d ' ')

        # Also check unstaged
        FILES_CHANGED_UNSTAGED=$(git diff --name-only 2>/dev/null | wc -l | tr -d ' ')
        FILES_CHANGED=$((FILES_CHANGED + FILES_CHANGED_UNSTAGED))
    fi

    if [ "$FILES_CHANGED" -gt "$MAX_FILES_SIMPLE" ]; then
        add_complexity 2 "Multiple files changed ($FILES_CHANGED files)"
    fi

    if [ -n "$LINES_CHANGED" ] && [ "$LINES_CHANGED" -gt "$MAX_LINES_SIMPLE" ]; then
        add_complexity 2 "Large change ($LINES_CHANGED lines)"
    fi

    # Check if changes span multiple packages/modules
    PACKAGES_CHANGED=$(git diff --cached --name-only 2>/dev/null | cut -d'/' -f1-3 | sort -u | wc -l | tr -d ' ')
    if [ "$PACKAGES_CHANGED" -gt 2 ]; then
        add_complexity 1 "Multiple packages affected ($PACKAGES_CHANGED packages)"
    fi
fi

# ============================================================================
# SIGNAL 2: Check for architectural patterns
# ============================================================================
if git rev-parse --git-dir > /dev/null 2>&1; then
    CHANGED_FILES=$(git diff --cached --name-only 2>/dev/null)

    # New aggregate or entity
    if echo "$CHANGED_FILES" | grep -qE "(domain/model|entity|aggregate).*\.java"; then
        if git diff --cached --diff-filter=A | grep -qE "class.*Aggregate|class.*Entity"; then
            add_complexity 3 "New domain aggregate or entity"
        fi
    fi

    # New event schema
    if echo "$CHANGED_FILES" | grep -qE "\.(avsc|proto)$"; then
        add_complexity 2 "Event schema changes (requires compatibility check)"
    fi

    # New API endpoint
    if git diff --cached | grep -qE "@(RestController|RequestMapping|PostMapping|GetMapping)"; then
        if git diff --cached --diff-filter=A | grep -qE "@(PostMapping|GetMapping|PutMapping|DeleteMapping)"; then
            add_complexity 2 "New API endpoint"
        fi
    fi

    # Database migration
    if echo "$CHANGED_FILES" | grep -qE "db/migration|flyway"; then
        add_complexity 2 "Database migration"
    fi

    # Kafka consumer/producer
    if git diff --cached | grep -qE "(@KafkaListener|KafkaProducer|KafkaConsumer)"; then
        add_complexity 2 "Kafka consumer/producer changes"
    fi

    # Security-related changes
    if git diff --cached | grep -qE "(Security|Authentication|Authorization|@PreAuthorize|@Secured)"; then
        add_complexity 3 "Security-related changes"
    fi

    # Saga or distributed transaction
    if git diff --cached | grep -qE "(Saga|Orchestrat|Choreograph|CompensationHandler)"; then
        add_complexity 3 "Saga or distributed transaction"
    fi

    # Infrastructure/config changes
    if echo "$CHANGED_FILES" | grep -qE "(terraform|\.tf$|application\.yml|application\.yaml)"; then
        add_complexity 2 "Infrastructure or configuration changes"
    fi
fi

# ============================================================================
# SIGNAL 3: Check for complexity keywords in commit message or context
# ============================================================================
if git rev-parse --git-dir > /dev/null 2>&1; then
    RECENT_MSG=$(git log -1 --pretty=%B 2>/dev/null || echo "")

    # Check for complexity indicators in commit message
    if echo "$RECENT_MSG" | grep -qiE "(refactor|restructure|redesign|rewrite)"; then
        add_complexity 2 "Refactoring detected"
    fi

    if echo "$RECENT_MSG" | grep -qiE "(breaking|migration|upgrade)"; then
        add_complexity 2 "Breaking change or migration"
    fi

    if echo "$RECENT_MSG" | grep -qiE "(feature|feat)"; then
        add_complexity 1 "New feature"
    fi
fi

# ============================================================================
# SIGNAL 4: Check for test file changes
# ============================================================================
if git rev-parse --git-dir > /dev/null 2>&1; then
    TEST_FILES=$(git diff --cached --name-only 2>/dev/null | grep -E "Test\.java$|test_.*\.py$|.*\.test\.(ts|js)$" | wc -l | tr -d ' ')

    if [ "$TEST_FILES" -eq 0 ] && [ "$FILES_CHANGED" -gt 0 ]; then
        add_complexity 2 "No test files in change (tests needed)"
    fi
fi

# ============================================================================
# ASSESSMENT RESULT
# ============================================================================
echo ""
echo "Complexity Score: $complexity_score"
echo "Threshold: $COMPLEXITY_THRESHOLD"
echo ""

if [ ${#complexity_reasons[@]} -gt 0 ]; then
    echo "Complexity Factors:"
    for reason in "${complexity_reasons[@]}"; do
        echo "  • $reason"
    done
    echo ""
fi

# ============================================================================
# TRIGGER AUTO-REVIEW-LOOP FOR COMPLEX TASKS
# ============================================================================
if [ "$complexity_score" -ge "$COMPLEXITY_THRESHOLD" ]; then
    echo "⚠️  HIGH COMPLEXITY DETECTED"
    echo ""
    echo "This task requires enhanced review process:"
    echo "  ✓ Automatic code review"
    echo "  ✓ Iterative feedback loop"
    echo "  ✓ Automated testing"
    echo ""
    echo "TRIGGER: /auto-review-loop"
    echo ""
    echo "The auto-review-loop skill will:"
    echo "  1. Implement the changes"
    echo "  2. Run code review (everything-claude-code:code-reviewer)"
    echo "  3. Fix any issues found"
    echo "  4. Repeat steps 2-3 until LGTM"
    echo "  5. Run automated tests"
    echo "  6. Report results"
    echo ""
    echo "💡 To proceed with auto-review-loop, the user should confirm or Claude should invoke it automatically."

else
    echo "✅ Standard complexity - normal workflow"
    echo ""
    echo "Standard checks will apply:"
    echo "  • Security review (if API/auth changes)"
    echo "  • Test coverage (if Java files changed)"
    echo "  • Schema validation (if schema files changed)"
fi

exit 0
