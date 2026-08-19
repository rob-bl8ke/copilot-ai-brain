#!/bin/bash
# Post-code hook: API Standards Conformance Check
#
# Checks REST API implementations for conformance with team standards

# Error handling
set -euo pipefail
trap 'echo "❌ API standards check hook failed at line $LINENO" >&2' ERR

# Logging setup
LOG_DIR="$HOME/.claude/hook-logs"
mkdir -p "$LOG_DIR" 2>/dev/null || true
LOG_FILE="$LOG_DIR/api-standards-check.log"
echo "$(date '+%Y-%m-%d %H:%M:%S') - Hook started" >> "$LOG_FILE" 2>/dev/null || true

# Check for REST API changes in working tree (staged + unstaged)
DIFF_CONTENT=$(git diff 2>/dev/null; git diff --cached 2>/dev/null)

# Check if diff contains REST API annotations
if ! echo "$DIFF_CONTENT" | grep -qE "@(RestController|Controller|RequestMapping|GetMapping|PostMapping|PutMapping|DeleteMapping|PatchMapping)"; then
    # No REST API changes detected
    exit 0
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "🔍 API Standards Conformance Check"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Use the already-captured diff for analysis
DIFF="$DIFF_CONTENT"

# Check 1: Required Request Headers
echo "📥 Request Headers Check"
echo ""

MISSING_HEADERS=()

if ! echo "$DIFF" | grep -q "@RequestHeader.*Correlation-Id"; then
    MISSING_HEADERS+=("Correlation-Id")
fi

if ! echo "$DIFF" | grep -q "@RequestHeader.*Session-Id"; then
    MISSING_HEADERS+=("Session-Id")
fi

if ! echo "$DIFF" | grep -q "@RequestHeader.*Request-Id"; then
    MISSING_HEADERS+=("Request-Id")
fi

if ! echo "$DIFF" | grep -q "@RequestHeader.*User-Ref"; then
    MISSING_HEADERS+=("User-Ref")
fi

if ! echo "$DIFF" | grep -q "@RequestHeader.*Channel"; then
    MISSING_HEADERS+=("Channel")
fi

if [ ${#MISSING_HEADERS[@]} -gt 0 ]; then
    echo "   ⚠️  Missing required request headers:"
    for header in "${MISSING_HEADERS[@]}"; do
        echo "      - $header"
    done
    echo ""
    echo "   Required headers:"
    echo "      @RequestHeader(\"Correlation-Id\") String correlationId"
    echo "      @RequestHeader(\"Session-Id\") String sessionId"
    echo "      @RequestHeader(\"Request-Id\") String requestId"
    echo "      @RequestHeader(\"User-Ref\") String userRef"
    echo "      @RequestHeader(\"Channel\") String channel"
    echo ""
else
    echo "   ✅ All required request headers present"
    echo ""
fi

# Check 2: Deprecated X- Headers
echo "📝 Deprecated Headers Check"
echo ""

if echo "$DIFF" | grep -qE '@RequestHeader.*"X-'; then
    echo "   ❌ DEPRECATED: X- prefixed headers detected!"
    echo "   Found X- headers (deprecated per RFC 6648):"
    echo "$DIFF" | grep -E '@RequestHeader.*"X-' | sed 's/^/      /'
    echo ""
    echo "   Fix: Remove 'X-' prefix from custom headers"
    echo "   Example: X-Correlation-Id → Correlation-Id"
    echo ""
else
    echo "   ✅ No deprecated X- headers found"
    echo ""
fi

# Check 3: Response Headers
echo "📤 Response Headers Check"
echo ""

MISSING_RESPONSE_HEADERS=()

if ! echo "$DIFF" | grep -qE "\.header\(\"Trace-Id\""; then
    MISSING_RESPONSE_HEADERS+=("Trace-Id")
fi

if ! echo "$DIFF" | grep -qE "\.header\(\"Timestamp\""; then
    MISSING_RESPONSE_HEADERS+=("Timestamp")
fi

if [ ${#MISSING_RESPONSE_HEADERS[@]} -gt 0 ]; then
    echo "   ⚠️  Missing required response headers:"
    for header in "${MISSING_RESPONSE_HEADERS[@]}"; do
        echo "      - $header"
    done
    echo ""
    echo "   Add to all responses:"
    echo "      return ResponseEntity.ok()"
    echo "          .header(\"Trace-Id\", traceId)"
    echo "          .header(\"Timestamp\", Instant.now().toString())"
    echo "          .body(response);"
    echo ""
else
    echo "   ✅ Response headers present"
    echo ""
fi

# Check 4: Error Response Structure
echo "🚨 Error Response Check"
echo ""

HAS_ERROR_HANDLER=$(echo "$DIFF" | grep -qE "@ExceptionHandler|ErrorResponse" && echo "yes" || echo "no")

if [ "$HAS_ERROR_HANDLER" = "yes" ]; then
    # Check for standard ErrorResponse fields
    MISSING_ERROR_FIELDS=()

    if ! echo "$DIFF" | grep -qE "(\.type|\"type\")"; then
        MISSING_ERROR_FIELDS+=("type (BUSINESS or TECHNICAL)")
    fi

    if ! echo "$DIFF" | grep -qE "(\.code|\"code\")"; then
        MISSING_ERROR_FIELDS+=("code (error code)")
    fi

    if ! echo "$DIFF" | grep -qE "(\.message|\"message\")"; then
        MISSING_ERROR_FIELDS+=("message")
    fi

    if ! echo "$DIFF" | grep -qE "(\.traceId|\"traceId\")"; then
        MISSING_ERROR_FIELDS+=("traceId")
    fi

    if ! echo "$DIFF" | grep -qE "(\.timestamp|\"timestamp\")"; then
        MISSING_ERROR_FIELDS+=("timestamp")
    fi

    if [ ${#MISSING_ERROR_FIELDS[@]} -gt 0 ]; then
        echo "   ⚠️  Error response may be missing fields:"
        for field in "${MISSING_ERROR_FIELDS[@]}"; do
            echo "      - $field"
        done
        echo ""
        echo "   Standard ErrorResponse structure:"
        echo "      {"
        echo "        \"type\": \"BUSINESS\" or \"TECHNICAL\","
        echo "        \"code\": \"ERROR_CODE\","
        echo "        \"message\": \"Human-readable message\","
        echo "        \"traceId\": \"trace-id-uuid\","
        echo "        \"timestamp\": \"2025-11-21T10:30:00Z\""
        echo "      }"
        echo ""
    else
        echo "   ✅ Error response structure looks correct"
        echo ""
    fi
else
    echo "   ℹ️  No error handlers detected in this change"
    echo ""
fi

# Check 5: Metadata Pollution in Payload
echo "📦 Payload Cleanliness Check"
echo ""

METADATA_IN_PAYLOAD=()

# Check for common metadata fields in response bodies
if echo "$DIFF" | grep -qE "\"traceId\".*:"; then
    METADATA_IN_PAYLOAD+=("traceId in payload (should be in header)")
fi

if echo "$DIFF" | grep -qE "\"timestamp\".*:"; then
    METADATA_IN_PAYLOAD+=("timestamp in payload (should be in header)")
fi

if echo "$DIFF" | grep -qE "\"paging\".*:"; then
    METADATA_IN_PAYLOAD+=("paging in payload (should be in headers)")
fi

if echo "$DIFF" | grep -qE "\"page\".*:"; then
    METADATA_IN_PAYLOAD+=("page in payload (should be X-Page header)")
fi

if [ ${#METADATA_IN_PAYLOAD[@]} -gt 0 ]; then
    echo "   ⚠️  Metadata pollution detected:"
    for issue in "${METADATA_IN_PAYLOAD[@]}"; do
        echo "      - $issue"
    done
    echo ""
    echo "   Fix: Move metadata to headers, keep payload clean"
    echo "   Correct:"
    echo "      Headers: Trace-Id, Timestamp, X-Page, X-Page-Size"
    echo "      Body: { \"customerId\": \"123\", ... } (data only)"
    echo ""
else
    echo "   ✅ Payload appears clean (no metadata pollution)"
    echo ""
fi

# Check 6: Error Type Correctness
echo "🔖 Error Type Classification Check"
echo ""

# Check for potential misclassification
if echo "$DIFF" | grep -qE "HttpStatus\.(BAD_REQUEST|UNAUTHORIZED|FORBIDDEN|NOT_FOUND)"; then
    if echo "$DIFF" | grep -qE "\"type\".*:.*\"TECHNICAL\""; then
        echo "   ⚠️  Potential misclassification:"
        echo "      4xx errors should have type=\"BUSINESS\""
        echo "      5xx errors should have type=\"TECHNICAL\""
        echo ""
        echo "   Rule:"
        echo "      Client error (4xx) → type: BUSINESS"
        echo "      Server error (5xx) → type: TECHNICAL"
        echo ""
    else
        echo "   ✅ Error type classification looks correct"
        echo ""
    fi
else
    echo "   ℹ️  No error status codes detected in this change"
    echo ""
fi

echo "════════════════════════════════════════════════════════════════"
echo ""
echo "💡 API Standards Reference: ~/team-claude-config/skills/api-standards/SKILL.md"
echo ""

echo "$(date '+%Y-%m-%d %H:%M:%S') - Hook completed successfully" >> "$LOG_FILE" 2>/dev/null || true
exit 0
