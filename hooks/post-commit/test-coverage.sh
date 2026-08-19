#!/bin/bash
# Pre-commit hook: Enforce 80% test coverage for Java changes
#
# Checks:
# 1. Corresponding test files exist for modified source files
# 2. If JaCoCo report is available, verifies actual coverage percentages
# 3. Blocks commit if coverage is below 80% (when report available)

# Error handling
set -euo pipefail
trap 'echo "❌ Test coverage hook failed at line $LINENO" >&2' ERR

# Logging setup
LOG_DIR="$HOME/.claude/hook-logs"
mkdir -p "$LOG_DIR" 2>/dev/null || true
LOG_FILE="$LOG_DIR/test-coverage.log"
echo "$(date '+%Y-%m-%d %H:%M:%S') - Hook started" >> "$LOG_FILE" 2>/dev/null || true

# Coverage threshold
COVERAGE_THRESHOLD=80

# Check if any Java files were modified
JAVA_FILES=$(git diff --cached --name-only --diff-filter=AM | grep "\.java$" | grep -v "Test\.java$" || true)

if [ -z "$JAVA_FILES" ]; then
    # No Java files changed, skip coverage check
    exit 0
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "📊 Test Coverage Check"
echo "════════════════════════════════════════════════════════════════"
echo ""

# ============================================================================
# Check 1: Corresponding test files exist
# ============================================================================
MISSING_TESTS=()
CHECKED_FILES=0

for file in $JAVA_FILES; do
    # Skip configuration, DTOs, and mappers
    if echo "$file" | grep -qE "(Config\.java|DTO\.java|Configuration\.java|Mapper\.java|Constants\.java|Application\.java)"; then
        continue
    fi

    CHECKED_FILES=$((CHECKED_FILES + 1))

    # Convert src/main/java path to src/test/java
    TEST_FILE=$(echo "$file" | sed 's/src\/main\/java/src\/test\/java/' | sed 's/\.java$/Test.java/')

    if [ ! -f "$TEST_FILE" ]; then
        MISSING_TESTS+=("$TEST_FILE")
    fi
done

if [ ${#MISSING_TESTS[@]} -gt 0 ]; then
    echo "⚠️  Missing test files (${#MISSING_TESTS[@]} of $CHECKED_FILES source files):"
    for test in "${MISSING_TESTS[@]}"; do
        echo "   • $test"
    done
    echo ""
fi

# ============================================================================
# Check 2: JaCoCo report analysis (if available)
# ============================================================================
JACOCO_REPORT=""

# Search for JaCoCo XML report in common locations
for report_path in \
    "target/site/jacoco/jacoco.xml" \
    "target/jacoco/jacoco.xml" \
    "build/reports/jacoco/test/jacocoTestReport.xml"; do
    if [ -f "$report_path" ]; then
        JACOCO_REPORT="$report_path"
        break
    fi
done

if [ -n "$JACOCO_REPORT" ]; then
    echo "📈 JaCoCo report found: $JACOCO_REPORT"
    echo ""

    # Parse overall coverage from JaCoCo XML
    # Look for the overall counter with type="LINE"
    MISSED=$(grep -o 'type="LINE" missed="[0-9]*"' "$JACOCO_REPORT" | tail -1 | grep -o '[0-9]*' || echo "0")
    COVERED=$(grep -o 'type="LINE" missed="[0-9]*" covered="[0-9]*"' "$JACOCO_REPORT" | tail -1 | grep -o 'covered="[0-9]*"' | grep -o '[0-9]*' || echo "0")

    if [ "$MISSED" != "0" ] || [ "$COVERED" != "0" ]; then
        TOTAL=$((MISSED + COVERED))
        if [ "$TOTAL" -gt 0 ]; then
            COVERAGE=$((COVERED * 100 / TOTAL))

            echo "   Line coverage: ${COVERAGE}% (${COVERED}/${TOTAL} lines)"
            echo "   Threshold:     ${COVERAGE_THRESHOLD}%"
            echo ""

            if [ "$COVERAGE" -lt "$COVERAGE_THRESHOLD" ]; then
                echo "❌ COVERAGE BELOW THRESHOLD: ${COVERAGE}% < ${COVERAGE_THRESHOLD}%"
                echo ""
                echo "   Run: mvn test jacoco:report"
                echo "   View: open target/site/jacoco/index.html"
                echo ""
                echo "⛔ Commit blocked. Increase test coverage to at least ${COVERAGE_THRESHOLD}%."
                echo ""
                exit 1
            else
                echo "✅ Coverage meets threshold: ${COVERAGE}% >= ${COVERAGE_THRESHOLD}%"
                echo ""
            fi
        fi
    else
        echo "   ⚠️  Could not parse coverage numbers from report."
        echo ""
    fi
else
    echo "ℹ️  No JaCoCo report found (advisory mode)."
    echo "   Run 'mvn test jacoco:report' to generate and enable enforcement."
    echo ""
fi

# ============================================================================
# Summary
# ============================================================================
if [ ${#MISSING_TESTS[@]} -gt 0 ]; then
    echo "────────────────────────────────────────────────────────────────"
    echo "ACTION REQUIRED:"
    echo "  1. Create missing test files"
    echo "  2. Run: mvn test jacoco:report"
    echo "  3. Verify ${COVERAGE_THRESHOLD}% coverage before pushing"
    echo "────────────────────────────────────────────────────────────────"
    echo ""
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') - Hook completed successfully" >> "$LOG_FILE" 2>/dev/null || true
exit 0
