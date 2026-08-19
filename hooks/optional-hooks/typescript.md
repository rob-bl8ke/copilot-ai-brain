## Hook Setup

```json
{
  "name": "TypeScript Type Checker",
  "description": "Automatically runs tsc --noEmit after editing TypeScript files to catch type errors immediately",
  "category": "code-quality",
  "impact": "medium",
  "performance": "~1-2s per edit",
  "recommended": true,
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "tool == \"Edit\" && tool_input.file_path matches \"\\\\.(ts|tsx)$\"",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"${TEAM_CLAUDE_CONFIG}/optional-hooks/typescript/check-types.sh\""
          }
        ],
        "description": "TypeScript type check after editing .ts/.tsx files"
      }
    ]
  }
}
```

## Hook

```bash
#!/bin/bash
# TypeScript type checker hook
# Runs tsc --noEmit after editing TypeScript files

set -e

# Read input from stdin
INPUT_JSON=$(cat)

# Parse file path using python
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

# Find tsconfig.json by walking up directory tree
DIR=$(dirname "$FILE_PATH")
while [ "$DIR" != "/" ] && [ ! -f "$DIR/tsconfig.json" ]; do
    DIR=$(dirname "$DIR")
done

# Exit if no tsconfig.json found
if [ ! -f "$DIR/tsconfig.json" ]; then
    echo "$INPUT_JSON"
    exit 0
fi

# Run TypeScript compiler in check mode
# Capture errors related to the edited file only
TSC_OUTPUT=$(cd "$DIR" && npx tsc --noEmit --pretty false 2>&1 || true)

# Filter for errors in the edited file (show max 10 lines)
RELEVANT_ERRORS=$(echo "$TSC_OUTPUT" | grep "$FILE_PATH" | head -10)

if [ -n "$RELEVANT_ERRORS" ]; then
    echo "[TypeScript Hook] Type errors detected:" >&2
    echo "$RELEVANT_ERRORS" >&2
    echo "" >&2
fi

# Always output original input (don't block)
echo "$INPUT_JSON"
```
