#!/bin/bash
# Post-code hook: SOLID principles reminder
#
# Provides checklist for SOLID principles after code changes

# Error handling
set -euo pipefail
trap 'echo "❌ SOLID check hook failed at line $LINENO" >&2' ERR

# Logging setup
LOG_DIR="$HOME/.claude/hook-logs"
mkdir -p "$LOG_DIR" 2>/dev/null || true
LOG_FILE="$LOG_DIR/solid-check.log"
echo "$(date '+%Y-%m-%d %H:%M:%S') - Hook started" >> "$LOG_FILE" 2>/dev/null || true

# Check both staged and unstaged changes (PostToolUse context = uncommitted changes)
CHANGED_FILES=$(git diff --name-only 2>/dev/null | grep -E "\.java$")
if [ -z "$CHANGED_FILES" ]; then
    CHANGED_FILES=$(git diff --cached --name-only 2>/dev/null | grep -E "\.java$")
fi
if [ -z "$CHANGED_FILES" ]; then
    # Fallback: check recently modified Java files in working tree
    CHANGED_FILES=$(git status --porcelain 2>/dev/null | grep -E "\.java$" | awk '{print $NF}')
fi

if [ -z "$CHANGED_FILES" ]; then
    exit 0
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "🧩 SOLID Principles Checklist"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Check what changed
# Combine staged + unstaged diff for analysis
DIFF_CONTENT=$(git diff 2>/dev/null; git diff --cached 2>/dev/null)

HAS_NEW_CLASS=$(git status --porcelain 2>/dev/null | grep -E "^\?\?.*\.java$" && echo "yes" || echo "no")
HAS_INTERFACE=$(echo "$DIFF_CONTENT" | grep -qE "^[\+].*interface" && echo "yes" || echo "no")
HAS_SERVICE=$(echo "$CHANGED_FILES" | grep -qE "(Service|UseCase)\.java$" && echo "yes" || echo "no")

# Single Responsibility Principle
echo "1️⃣  Single Responsibility Principle (SRP)"
echo "   ✓ Does each class have one reason to change?"
echo "   ✓ Can you describe the class without using 'and' or 'or'?"
if [ "$HAS_SERVICE" = "yes" ]; then
    echo "   ⚠️  Service detected - ensure it's not a god class"
fi
echo ""

# Open/Closed Principle
echo "2️⃣  Open/Closed Principle (OCP)"
echo "   ✓ Can you extend behavior without modifying existing code?"
echo "   ✓ Are you using interfaces/abstractions for variation?"
if echo "$DIFF_CONTENT" | grep -qE "switch.*\.(getType|getClass)"; then
    echo "   ⚠️  Type switching detected - consider polymorphism"
fi
echo ""

# Liskov Substitution Principle
echo "3️⃣  Liskov Substitution Principle (LSP)"
if [ "$HAS_NEW_CLASS" = "yes" ]; then
    if echo "$DIFF_CONTENT" | grep -qE "extends"; then
        echo "   ✓ Are subtypes substitutable for base types?"
        echo "   ✓ Do subtypes preserve base type behavior?"
        echo "   ⚠️  Inheritance detected - verify substitutability"
    else
        echo "   ✓ No inheritance changes"
    fi
fi
echo ""

# Interface Segregation Principle
echo "4️⃣  Interface Segregation Principle (ISP)"
if [ "$HAS_INTERFACE" = "yes" ]; then
    echo "   ✓ Do clients use all interface methods?"
    echo "   ✓ Are interfaces focused and cohesive?"
    echo "   ⚠️  New interface - ensure it's not too fat"
else
    echo "   ✓ No interface changes"
fi
echo ""

# Dependency Inversion Principle
echo "5️⃣  Dependency Inversion Principle (DIP)"
if echo "$DIFF_CONTENT" | grep -qE "new.*Repository|new.*Service"; then
    echo "   ⚠️  'new' operator detected - consider dependency injection"
fi
echo "   ✓ Are you depending on abstractions (interfaces)?"
echo "   ✓ Are concrete classes injected via constructor?"
echo ""

echo "════════════════════════════════════════════════════════════════"
echo ""
echo "💡 Tip: Run /clean-architecture to analyze SOLID compliance"
echo ""

echo "$(date '+%Y-%m-%d %H:%M:%S') - Hook completed successfully" >> "$LOG_FILE" 2>/dev/null || true
exit 0
