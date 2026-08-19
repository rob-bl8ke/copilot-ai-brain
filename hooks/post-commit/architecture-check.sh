
#!/bin/bash
# Pre-commit hook: Clean architecture and SOLID enforcement
#
# Detects layer violations, SOLID violations, and dependency rule breaks
# Triggers architect agent for review

# Error handling
set -euo pipefail
trap 'echo "❌ Architecture check hook failed at line $LINENO" >&2' ERR

# Logging setup
LOG_DIR="$HOME/.claude/hook-logs"
mkdir -p "$LOG_DIR" 2>/dev/null || true
LOG_FILE="$LOG_DIR/architecture-check.log"
echo "$(date '+%Y-%m-%d %H:%M:%S') - Hook started" >> "$LOG_FILE" 2>/dev/null || true

# Enforcement mode: "blocking" exits non-zero on violations, "advisory" warns only
# Override via environment variable or .claude/architecture-enforcement file
ENFORCEMENT_MODE="${ARCHITECTURE_ENFORCEMENT:-advisory}"
if [ -f "$HOME/.claude/architecture-enforcement" ]; then
    ENFORCEMENT_MODE=$(cat "$HOME/.claude/architecture-enforcement" | tr -d '[:space:]')
fi

echo "🏛️  Checking clean architecture compliance... (mode: $ENFORCEMENT_MODE)"

VIOLATIONS=0
BLOCKING_VIOLATIONS=0

# ============================================================================
# LAYER VIOLATION: Domain depends on infrastructure
# ============================================================================
if git diff --cached --diff-filter=AM | grep -E "^[\+].*import.*javax\.persistence\.|^[\+].*import.*org\.springframework\.(data|beans|context|transaction)"; then
    DOMAIN_FILES=$(git diff --cached --name-only | grep -E "domain/model/.*\.java$")

    if [ -n "$DOMAIN_FILES" ]; then
        echo ""
        echo "❌ LAYER VIOLATION [BLOCKING]: Domain depends on infrastructure"
        echo ""
        echo "Domain layer must be framework-agnostic."
        echo "Remove these imports from domain layer:"
        echo "  • javax.persistence.* (@Entity, @Id, @Column)"
        echo "  • org.springframework.data.* (JPA repositories)"
        echo "  • org.springframework.beans.* (@Autowired, @Component)"
        echo ""
        echo "Fix:"
        echo "  1. Remove framework annotations from domain entities"
        echo "  2. Create separate JPA entities in infrastructure layer"
        echo "  3. Use mapper to convert between domain and JPA entities"
        echo ""
        VIOLATIONS=$((VIOLATIONS + 1))
        BLOCKING_VIOLATIONS=$((BLOCKING_VIOLATIONS + 1))
    fi
fi

# ============================================================================
# LAYER VIOLATION: Application depends on infrastructure directly
# ============================================================================
if git diff --cached --diff-filter=AM | grep -E "^[\+].*import.*infrastructure\."; then
    APPLICATION_FILES=$(git diff --cached --name-only | grep -E "application/.*\.java$")

    if [ -n "$APPLICATION_FILES" ]; then
        echo ""
        echo "❌ LAYER VIOLATION [BLOCKING]: Application depends on infrastructure (concrete)"
        echo ""
        echo "Application should depend on domain interfaces, not infrastructure implementations."
        echo ""
        echo "Fix:"
        echo "  1. Define interfaces in domain layer"
        echo "  2. Implement in infrastructure layer"
        echo "  3. Application depends on domain interface only"
        echo ""
        echo "Example:"
        echo "  ✅ private final OrderRepository repo;  // Domain interface"
        echo "  ❌ private final JpaOrderRepository repo;  // Infrastructure concrete"
        echo ""
        VIOLATIONS=$((VIOLATIONS + 1))
        BLOCKING_VIOLATIONS=$((BLOCKING_VIOLATIONS + 1))
    fi
fi

# ============================================================================
# SOLID VIOLATION: God class detection (file size)
# ============================================================================
LARGE_FILES=$(git diff --cached --name-only | while read file; do
    if [ -f "$file" ]; then
        LINES=$(wc -l < "$file" | tr -d ' ')
        if [ "$LINES" -gt 500 ]; then
            echo "$file:$LINES"
        fi
    fi
done)

if [ -n "$LARGE_FILES" ]; then
    echo ""
    echo "⚠️  SOLID VIOLATION: Potential god class (SRP)"
    echo ""
    echo "Large files may violate Single Responsibility Principle:"
    while IFS=: read -r file lines; do
        echo "  • $file ($lines lines)"
    done <<< "$LARGE_FILES"
    echo ""
    echo "Consider:"
    echo "  1. Does this class have multiple responsibilities?"
    echo "  2. Can it be split into smaller, focused classes?"
    echo "  3. Is business logic mixed with orchestration?"
    echo ""
    VIOLATIONS=$((VIOLATIONS + 1))
fi

# ============================================================================
# SOLID VIOLATION: Anemic domain model detection
# ============================================================================
if git diff --cached --diff-filter=AM | grep -E "^[\+].*public void set[A-Z]"; then
    DOMAIN_ENTITIES=$(git diff --cached --name-only | grep -E "domain/model/.*\.java$")

    if [ -n "$DOMAIN_ENTITIES" ]; then
        echo ""
        echo "⚠️  ARCHITECTURE SMELL: Anemic domain model"
        echo ""
        echo "Domain entities have setters but may lack behavior."
        echo ""
        echo "DDD Principle:"
        echo "  Business logic belongs in domain entities, not services."
        echo ""
        echo "Instead of:"
        echo "  ❌ order.setStatus(SUBMITTED);  // In service"
        echo ""
        echo "Prefer:"
        echo "  ✅ order.submit();  // Business method in entity"
        echo ""
    fi
fi

# ============================================================================
# SOLID VIOLATION: Switch on type (OCP violation)
# ============================================================================
if git diff --cached --diff-filter=AM | grep -E "switch.*\.(getType|getClass|getKind)\(\)|if.*==.*Type\."; then
    echo ""
    echo "⚠️  SOLID VIOLATION: Type switching (OCP)"
    echo ""
    echo "Switching on type violates Open/Closed Principle."
    echo "Code must be modified for each new type."
    echo ""
    echo "Fix:"
    echo "  1. Create interface for behavior"
    echo "  2. Implement interface for each type"
    echo "  3. Use polymorphism instead of switch"
    echo ""
    echo "Example:"
    echo "  ❌ if (type == CREDIT_CARD) { ... } else if (type == EFT) { ... }"
    echo "  ✅ processor.process(payment);  // Polymorphism"
    echo ""
    VIOLATIONS=$((VIOLATIONS + 1))
fi

# ============================================================================
# DEPENDENCY RULE: Check imports in domain layer
# ============================================================================
DOMAIN_FILES=$(git diff --cached --name-only | grep -E "domain/.*\.java$")

if [ -n "$DOMAIN_FILES" ]; then
    for file in $DOMAIN_FILES; do
        if [ -f "$file" ]; then
            # Check for imports that violate dependency rule
            if grep -qE "^import.*(application|infrastructure|api|controller)" "$file"; then
                echo ""
                echo "❌ DEPENDENCY RULE VIOLATION [BLOCKING]: Domain depends on outer layers"
                echo ""
                echo "File: $file"
                echo ""
                echo "Domain layer must not depend on:"
                echo "  • Application layer"
                echo "  • Infrastructure layer"
                echo "  • Presentation layer"
                echo ""
                echo "Domain should be completely independent."
                echo ""
                VIOLATIONS=$((VIOLATIONS + 1))
                BLOCKING_VIOLATIONS=$((BLOCKING_VIOLATIONS + 1))
                break
            fi
        fi
    done
fi

# ============================================================================
# TRIGGER ARCHITECT AGENT FOR REVIEW
# ============================================================================
if [ $VIOLATIONS -gt 0 ]; then
    echo "════════════════════════════════════════════════════════════════"
    echo "🔍 ARCHITECTURE REVIEW REQUIRED"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    echo "Detected $VIOLATIONS violation(s): $BLOCKING_VIOLATIONS blocking, $((VIOLATIONS - BLOCKING_VIOLATIONS)) advisory."
    echo ""
    echo "TRIGGER: Architect agent review"
    echo ""
    echo "Recommended actions:"
    echo "  1. Run: /clean-architecture analyze"
    echo "  2. Or invoke: architect agent"
    echo "  3. Fix violations before committing"
    echo ""
    echo "Task(subagent_type=\"everything-claude-code:architect\", prompt=\"Review clean architecture and SOLID compliance\")"
    echo ""

    # Enforcement mode determines exit behavior
    if [ "$ENFORCEMENT_MODE" = "blocking" ] && [ $BLOCKING_VIOLATIONS -gt 0 ]; then
        echo "⛔ BLOCKED: $BLOCKING_VIOLATIONS layer/dependency violation(s) must be fixed."
        echo "   To switch to advisory mode: echo 'advisory' > ~/.claude/architecture-enforcement"
        echo ""
        exit 1
    fi

    exit 0
fi

echo "✅ Clean architecture checks passed"
echo "$(date '+%Y-%m-%d %H:%M:%S') - Hook completed successfully" >> "$LOG_FILE" 2>/dev/null || true
exit 0
