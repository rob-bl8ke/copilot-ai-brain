#!/bin/bash
# Pre-user-prompt hook: Assess task complexity from user request

# This hook runs BEFORE Claude processes the user's prompt
# It analyzes the request for complexity signals and suggests auto-review-loop

# Exit codes:
# 0 - Assessment complete, continue

# Complexity keywords that indicate complex tasks
COMPLEX_KEYWORDS=(
    "refactor"
    "redesign"
    "rewrite"
    "migration"
    "breaking change"
    "new feature"
    "implement.*authentication"
    "implement.*authorization"
    "implement.*payment"
    "implement.*saga"
    "distributed transaction"
    "event sourcing"
    "new aggregate"
    "new bounded context"
    "new microservice"
    "kafka.*integration"
    "schema.*change"
    "database.*migration"
)

# Moderate complexity keywords
MODERATE_KEYWORDS=(
    "add.*endpoint"
    "new.*api"
    "update.*model"
    "change.*schema"
    "add.*validation"
    "implement.*feature"
)

# Check if user's prompt indicates complex task
check_prompt_complexity() {
    local prompt="$1"
    local score=0

    # Convert to lowercase for matching
    prompt_lower=$(echo "$prompt" | tr '[:upper:]' '[:lower:]')

    # Check for complex keywords
    for keyword in "${COMPLEX_KEYWORDS[@]}"; do
        if echo "$prompt_lower" | grep -qE "$keyword"; then
            score=$((score + 3))
            echo "  • Detected: $keyword (+3 complexity)" >&2
        fi
    done

    # Check for moderate keywords
    for keyword in "${MODERATE_KEYWORDS[@]}"; do
        if echo "$prompt_lower" | grep -qE "$keyword"; then
            score=$((score + 1))
            echo "  • Detected: $keyword (+1 complexity)" >&2
        fi
    done

    # Check for multi-part tasks (contains "and" multiple times)
    and_count=$(echo "$prompt_lower" | grep -o " and " | wc -l | tr -d ' ')
    if [ "$and_count" -ge 2 ]; then
        score=$((score + 2))
        echo "  • Multi-part task detected (+2 complexity)" >&2
    fi

    # Check for explicit mention of multiple files/services
    if echo "$prompt_lower" | grep -qE "(multiple files|several files|across.*services)"; then
        score=$((score + 2))
        echo "  • Multi-file/service change (+2 complexity)" >&2
    fi

    echo "$score"
}

# Read user prompt from stdin or environment
USER_PROMPT="${CLAUDE_USER_PROMPT:-}"

if [ -z "$USER_PROMPT" ]; then
    # Try to read from stdin if available
    if [ ! -t 0 ]; then
        USER_PROMPT=$(cat)
    fi
fi

if [ -z "$USER_PROMPT" ]; then
    # No prompt available, skip assessment
    exit 0
fi

# Only assess if prompt looks like an implementation request
if ! echo "$USER_PROMPT" | grep -qiE "(implement|create|add|build|develop|write|refactor|change|update|fix)"; then
    # Not an implementation task, skip
    exit 0
fi

echo "🔍 Pre-flight task complexity assessment..."
echo ""

complexity_score=$(check_prompt_complexity "$USER_PROMPT")

echo ""
echo "Estimated Complexity Score: $complexity_score"
echo ""

# Suggest auto-review-loop for high complexity tasks
if [ "$complexity_score" -ge 5 ]; then
    echo "⚠️  HIGH COMPLEXITY TASK DETECTED"
    echo ""
    echo "Recommendation: Use auto-review-loop workflow"
    echo ""
    echo "This task should go through:"
    echo "  1. Implementation"
    echo "  2. Automated code review"
    echo "  3. Iterative fixes (up to 3 iterations)"
    echo "  4. Automated testing"
    echo ""
    echo "SUGGESTION: Trigger /auto-review-loop"
    echo ""
    echo "Example: '/auto-review-loop $USER_PROMPT'"
    echo ""

elif [ "$complexity_score" -ge 3 ]; then
    echo "⚡ MODERATE COMPLEXITY"
    echo ""
    echo "Standard workflow recommended with extra attention to:"
    echo "  • Code review after implementation"
    echo "  • Test coverage verification"
    echo "  • Security checks if applicable"
    echo ""

else
    echo "✅ Standard task complexity"
    echo ""
fi

exit 0
