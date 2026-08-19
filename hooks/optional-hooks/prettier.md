## Hook Setup

```json
{
  "name": "Prettier Auto-Formatter",
  "description": "Automatically formats JavaScript/TypeScript files with Prettier after edits",
  "category": "code-quality",
  "impact": "low",
  "performance": "~500ms per edit",
  "recommended": true,
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "tool == \"Edit\" && tool_input.file_path matches \"\\\\.(ts|tsx|js|jsx)$\"",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"${TEAM_CLAUDE_CONFIG}/optional-hooks/prettier/format-file.sh\""
          }
        ],
        "description": "Auto-format JS/TS files with Prettier after edits"
      }
    ]
  }
}
```

## Hook

```bash
#!/bin/bash
# Prettier auto-formatter hook
# Formats JavaScript/TypeScript files after edits

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

# Check if prettier is available
if ! command -v npx &> /dev/null; then
    echo "$INPUT_JSON"
    exit 0
fi

# Run prettier (silently, don't show errors)
npx prettier --write "$FILE_PATH" 2>/dev/null || true

# Output original input
echo "$INPUT_JSON"
```
