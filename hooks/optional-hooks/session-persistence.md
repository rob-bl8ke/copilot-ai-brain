## Hook Setup

```json
{
  "name": "Session Persistence",
  "description": "Saves and restores session context between Claude sessions",
  "category": "workflow",
  "impact": "medium",
  "performance": "~1s on session start/end",
  "recommended": true,
  "hooks": {
    "SessionStart": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"${TEAM_CLAUDE_CONFIG}/optional-hooks/session-persistence/session-start.sh\""
          }
        ],
        "description": "Restore previous session context"
      }
    ],
    "SessionEnd": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"${TEAM_CLAUDE_CONFIG}/optional-hooks/session-persistence/session-end.sh\""
          }
        ],
        "description": "Save session state"
      }
    ]
  }
}
```

## Hook (Session Start)

```bash
#!/bin/bash
# Session start hook
# Restores previous session context

set -e

SESSION_STATE_DIR="$HOME/.claude/team-session-state"
mkdir -p "$SESSION_STATE_DIR"

CURRENT_DIR=$(pwd)
STATE_FILE="$SESSION_STATE_DIR/$(echo $CURRENT_DIR | md5sum | cut -d' ' -f1).json"

if [ -f "$STATE_FILE" ]; then
    echo "[Session] 📂 Restoring previous session context..." >&2

    # Read previous state
    PREV_BRANCH=$(jq -r '.branch // "unknown"' "$STATE_FILE" 2>/dev/null || echo "unknown")
    PREV_FILES=$(jq -r '.recent_files[]? // empty' "$STATE_FILE" 2>/dev/null || echo "")

    if [ "$PREV_BRANCH" != "unknown" ]; then
        echo "[Session] Previous branch: $PREV_BRANCH" >&2
    fi

    if [ -n "$PREV_FILES" ]; then
        echo "[Session] Recently edited files:" >&2
        echo "$PREV_FILES" | head -5 | sed 's/^/  - /' >&2
    fi

    echo "" >&2
fi

exit 0
```

## Hook (Session End)

```bash
#!/bin/bash
# Session end hook
# Saves session state for next session

set -e

SESSION_STATE_DIR="$HOME/.claude/team-session-state"
mkdir -p "$SESSION_STATE_DIR"

CURRENT_DIR=$(pwd)
STATE_FILE="$SESSION_STATE_DIR/$(echo $CURRENT_DIR | md5sum | cut -d' ' -f1).json"

# Collect session state
BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")

# Get recently modified files from git
RECENT_FILES=$(git diff --name-only HEAD~5..HEAD 2>/dev/null | head -10 || echo "")

# Build JSON state
python3 << EOF > "$STATE_FILE"
import json
import sys

state = {
    "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "directory": "$CURRENT_DIR",
    "branch": "$BRANCH",
    "recent_files": $(echo "$RECENT_FILES" | jq -R -s -c 'split("\n") | map(select(length > 0))')
}

print(json.dumps(state, indent=2))
EOF

echo "[Session] 💾 Session state saved" >&2

exit 0
```
