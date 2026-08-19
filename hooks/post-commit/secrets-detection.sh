#!/bin/bash
# Pre-commit hook: Detect hardcoded secrets, credentials, and sensitive data
#
# Catches common secret patterns before they enter version control

# Error handling
set -euo pipefail
trap 'echo "❌ Secrets detection hook failed at line $LINENO" >&2' ERR

# Logging setup
LOG_DIR="$HOME/.claude/hook-logs"
mkdir -p "$LOG_DIR" 2>/dev/null || true
LOG_FILE="$LOG_DIR/secrets-detection.log"
echo "$(date '+%Y-%m-%d %H:%M:%S') - Hook started" >> "$LOG_FILE" 2>/dev/null || true

# Get staged diff content (only additions)
STAGED_DIFF=$(git diff --cached --diff-filter=AM 2>/dev/null)

if [ -z "$STAGED_DIFF" ]; then
    exit 0
fi

SECRETS_FOUND=0

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "🔐 Secrets Detection Check"
echo "════════════════════════════════════════════════════════════════"
echo ""

# ============================================================================
# Pattern 1: Hardcoded passwords and secrets in code
# ============================================================================
if echo "$STAGED_DIFF" | grep -nE '^\+.*((password|passwd|pwd)\s*[=:]\s*"[^"${}]+")' | grep -vE '(//.*|/\*.*|\*.*|#.*)' | head -5 | grep -q .; then
    echo "❌ HARDCODED PASSWORD detected in staged changes:"
    echo "$STAGED_DIFF" | grep -nE '^\+.*((password|passwd|pwd)\s*[=:]\s*"[^"${}]+")' | grep -vE '(//.*|/\*.*|\*.*|#.*)' | head -5 | sed 's/^/   /'
    echo ""
    SECRETS_FOUND=$((SECRETS_FOUND + 1))
fi

# ============================================================================
# Pattern 2: AWS credentials
# ============================================================================
if echo "$STAGED_DIFF" | grep -nE '^\+.*(AKIA[0-9A-Z]{16}|aws_secret_access_key\s*[=:])' | head -5 | grep -q .; then
    echo "❌ AWS CREDENTIALS detected in staged changes:"
    echo "$STAGED_DIFF" | grep -nE '^\+.*(AKIA[0-9A-Z]{16}|aws_secret_access_key\s*[=:])' | head -3 | sed 's/^/   /'
    echo ""
    SECRETS_FOUND=$((SECRETS_FOUND + 1))
fi

# ============================================================================
# Pattern 3: API keys and tokens
# ============================================================================
if echo "$STAGED_DIFF" | grep -nE '^\+.*(api[_-]?key|api[_-]?secret|access[_-]?token|auth[_-]?token)\s*[=:]\s*"[^"${}]+"' | grep -vE '(//.*|/\*.*|\*.*|#.*|example|placeholder|TODO)' | head -5 | grep -q .; then
    echo "❌ API KEY/TOKEN detected in staged changes:"
    echo "$STAGED_DIFF" | grep -nE '^\+.*(api[_-]?key|api[_-]?secret|access[_-]?token|auth[_-]?token)\s*[=:]\s*"[^"${}]+"' | grep -vE '(//.*|/\*.*|\*.*|#.*|example|placeholder|TODO)' | head -3 | sed 's/^/   /'
    echo ""
    SECRETS_FOUND=$((SECRETS_FOUND + 1))
fi

# ============================================================================
# Pattern 4: Private keys
# ============================================================================
if echo "$STAGED_DIFF" | grep -nE '^\+.*(BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY)' | head -3 | grep -q .; then
    echo "❌ PRIVATE KEY detected in staged changes!"
    echo "   Private keys must NEVER be committed to version control."
    echo ""
    SECRETS_FOUND=$((SECRETS_FOUND + 1))
fi

# ============================================================================
# Pattern 5: Connection strings with embedded credentials
# ============================================================================
if echo "$STAGED_DIFF" | grep -nE '^\+.*(jdbc|postgresql|mysql|mongodb|redis)://[^:]+:[^@${}]+@' | grep -vE '\$\{' | head -5 | grep -q .; then
    echo "❌ CONNECTION STRING WITH CREDENTIALS detected:"
    echo "$STAGED_DIFF" | grep -nE '^\+.*(jdbc|postgresql|mysql|mongodb|redis)://[^:]+:[^@${}]+@' | grep -vE '\$\{' | head -3 | sed 's/^/   /'
    echo ""
    echo "   Fix: Use environment variables or Vault references:"
    echo "   ✅ jdbc:postgresql://\${RDS_HOSTNAME}:\${RDS_PORT}/\${DB_NAME}"
    echo "   ❌ jdbc:postgresql://user:password@host:5432/db"
    echo ""
    SECRETS_FOUND=$((SECRETS_FOUND + 1))
fi

# ============================================================================
# Pattern 6: Sensitive files being committed
# ============================================================================
SENSITIVE_FILES=$(git diff --cached --name-only 2>/dev/null | grep -iE "(\.env$|\.env\.|credentials|\.pem$|\.key$|\.p12$|\.jks$|\.keystore$)" || true)

if [ -n "$SENSITIVE_FILES" ]; then
    echo "❌ SENSITIVE FILES staged for commit:"
    echo "$SENSITIVE_FILES" | sed 's/^/   • /'
    echo ""
    echo "   These files should be in .gitignore"
    echo ""
    SECRETS_FOUND=$((SECRETS_FOUND + 1))
fi

# ============================================================================
# Pattern 7: Vault/secrets manager hardcoded values (not references)
# ============================================================================
if echo "$STAGED_DIFF" | grep -nE '^\+.*(vault\.hashicorp|secretsmanager).*[=:]\s*"[^${}]+"' | head -3 | grep -q .; then
    echo "⚠️  Vault/SecretsManager reference check:"
    echo "   Ensure values are references (\${vault:path}), not hardcoded."
    echo ""
fi

# ============================================================================
# RESULT
# ============================================================================
if [ $SECRETS_FOUND -gt 0 ]; then
    echo "════════════════════════════════════════════════════════════════"
    echo "⛔ BLOCKED: $SECRETS_FOUND secret pattern(s) detected"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    echo "Secrets must NEVER be committed to version control."
    echo ""
    echo "Recommended approach:"
    echo "  • Use AWS Secrets Manager or Vault for secrets"
    echo "  • Use environment variables with \${VAR} references"
    echo "  • Use Spring Boot externalized config"
    echo "  • Add sensitive files to .gitignore"
    echo ""
    echo "If this is a false positive (test data, examples), add a comment:"
    echo "  // NOSONAR - test data, not a real secret"
    echo ""
    exit 1
fi

echo "✅ No secrets detected in staged changes"
echo "$(date '+%Y-%m-%d %H:%M:%S') - Hook completed successfully" >> "$LOG_FILE" 2>/dev/null || true
exit 0
