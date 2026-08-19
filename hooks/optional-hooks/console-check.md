## Hook Setup

```json
{
  "name": "Console.log Detector",
  "description": "Warns about console.log statements after editing JavaScript/TypeScript files",
  "category": "code-quality",
  "impact": "low",
  "performance": "~100ms per edit",
  "recommended": true,
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "tool == \"Edit\" && tool_input.file_path matches \"\\\\.(ts|tsx|js|jsx)$\"",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"${TEAM_CLAUDE_CONFIG}/optional-hooks/console-check/check-console.sh\""
          }
        ],
        "description": "Warn about console.log statements after edits"
      }
    ]
  }
}
```

## Hook

```bash
#!/bin/bash
# Console.log detector hook
# Warns about console.log statements in edited files

set -e

# Read input from stdin
INPUT_JSON=$(cat)

# Parse file path
FILE_PATH=$(echo "$INPUT_JSON" | python3 -c "
import json, sys
try:
    data = json.loads(sys.stdin.read())
    print(data.get('tool_input', {}).get('file_path', ''))
except:
    pass
")

# Exit if no file path or file doesn't exist
if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
    echo "$INPUT_JSON"
    exit 0
fi

# Check for console.log statements
CONSOLE_LOGS=$(grep -n "console\.log" "$FILE_PATH" 2>/dev/null || true)

if [ -n "$CONSOLE_LOGS" ]; then
    echo "[Console Hook] WARNING: console.log found in $FILE_PATH" >&2
    echo "$CONSOLE_LOGS" | head -5 >&2
    echo "[Console Hook] Remove console.log statements before committing" >&2
    echo "" >&2
fi

# Output original input
echo "$INPUT_JSON"
```
