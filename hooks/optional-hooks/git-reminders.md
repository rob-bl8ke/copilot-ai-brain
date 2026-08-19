## Hook Setup

```json
{
  "name": "Git Push Reminder",
  "description": "Gentle reminder to review changes before pushing to remote",
  "category": "git",
  "impact": "low",
  "performance": "instant",
  "recommended": false,
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "tool == \"Bash\" && tool_input.command matches \"git push\"",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"${TEAM_CLAUDE_CONFIG}/optional-hooks/git-reminders/push-reminder.sh\""
          }
        ],
        "description": "Reminder before git push to review changes"
      }
    ]
  }
}
```

## Hook

```bash
#!/bin/bash
# Git push reminder hook
# Reminds to review changes before pushing

set -e

# Read input
INPUT_JSON=$(cat)

# Show reminder
echo "[Git Hook] 💡 Reminder: Review changes before pushing" >&2
echo "[Git Hook] Run: git log --oneline -5 && git diff origin/\$(git branch --show-current)" >&2
echo "" >&2

# Output original input (don't block)
echo "$INPUT_JSON"
```
