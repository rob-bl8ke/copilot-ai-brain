# Optional Productivity Hooks

Optional hooks that individual engineers can choose to enable for improved productivity and code quality.

## Available Hooks

### ✅ Recommended

#### 1. TypeScript Type Checker
**Category:** Code Quality
**Performance Impact:** ~1-2s per edit
**Description:** Automatically runs `tsc --noEmit` after editing TypeScript files to catch type errors immediately.

**Benefits:**
- Catches type errors before running code
- Shows errors for edited file only
- Non-blocking (shows warnings but continues)

**When to use:** If you work with TypeScript regularly

---

#### 2. Prettier Auto-Formatter
**Category:** Code Quality
**Performance Impact:** ~500ms per edit
**Description:** Automatically formats JavaScript/TypeScript files with Prettier after edits.

**Benefits:**
- Consistent code formatting
- No manual formatting needed
- Integrates with project's prettier config

**When to use:** For consistent formatting across team

---

#### 3. Console.log Detector
**Category:** Code Quality
**Performance Impact:** ~100ms per edit
**Description:** Warns about `console.log` statements after editing JavaScript/TypeScript files.

**Benefits:**
- Catches debug statements before commit
- Prevents console.log pollution in production
- Shows first 5 occurrences

**When to use:** Always (good practice check)

---

#### 4. Session Persistence
**Category:** Workflow
**Performance Impact:** ~1s on session start/end
**Description:** Saves and restores session context between Claude sessions.

**Benefits:**
- Restores branch info on new session
- Shows recently edited files
- Maintains context across sessions

**When to use:** For continuity between work sessions

---

### ⚠️ Optional

#### 5. Git Push Reminder
**Category:** Git
**Performance Impact:** Instant
**Description:** Gentle reminder to review changes before pushing to remote.

**Benefits:**
- Prevents accidental pushes
- Suggests review commands
- Non-blocking reminder

**When to use:** If you want extra safety before pushes

---

## How to Enable

### Option 1: Enable Individual Hooks (Recommended)

Edit your `~/.claude/settings.json`:

```json
{
  "skillDirectories": [
    "~/team-claude-config/skills",
    "~/.claude/skills"
  ],
  "hooksDirectory": "~/team-claude-config/hooks",
  "env": {
    "TEAM_CLAUDE_CONFIG": "~/team-claude-config"
  },
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "tool == \"Edit\" && tool_input.file_path matches \"\\\\.(ts|tsx)$\"",
        "hooks": [{
          "type": "command",
          "command": "bash \"${TEAM_CLAUDE_CONFIG}/optional-hooks/typescript/check-types.sh\""
        }],
        "description": "TypeScript type check after edits"
      },
      {
        "matcher": "tool == \"Edit\" && tool_input.file_path matches \"\\\\.(ts|tsx|js|jsx)$\"",
        "hooks": [{
          "type": "command",
          "command": "bash \"${TEAM_CLAUDE_CONFIG}/optional-hooks/prettier/format-file.sh\""
        }],
        "description": "Auto-format with Prettier"
      },
      {
        "matcher": "tool == \"Edit\" && tool_input.file_path matches \"\\\\.(ts|tsx|js|jsx)$\"",
        "hooks": [{
          "type": "command",
          "command": "bash \"${TEAM_CLAUDE_CONFIG}/optional-hooks/console-check/check-console.sh\""
        }],
        "description": "Check for console.log"
      }
    ],
    "SessionStart": [
      {
        "matcher": "*",
        "hooks": [{
          "type": "command",
          "command": "bash \"${TEAM_CLAUDE_CONFIG}/optional-hooks/session-persistence/session-start.sh\""
        }],
        "description": "Restore session context"
      }
    ],
    "SessionEnd": [
      {
        "matcher": "*",
        "hooks": [{
          "type": "command",
          "command": "bash \"${TEAM_CLAUDE_CONFIG}/optional-hooks/session-persistence/session-end.sh\""
        }],
        "description": "Save session state"
      }
    ]
  }
}
```

### Option 2: Use Enable Script

Run the interactive setup script:

```bash
cd ~/team-claude-config
./scripts/enable-optional-hooks.sh
```

This will prompt you to select which hooks to enable.

### Option 3: Enable Specific Hook

To enable just one hook:

```bash
# TypeScript checker only
./scripts/enable-hook.sh typescript

# Prettier only
./scripts/enable-hook.sh prettier

# All recommended
./scripts/enable-hook.sh all-recommended
```

## Hook Details

### TypeScript Type Checker

**Location:** `optional-hooks/typescript/`

**What it does:**
1. Detects TypeScript file edits
2. Finds nearest `tsconfig.json`
3. Runs `tsc --noEmit` in check mode
4. Shows errors for edited file only (max 10 lines)
5. Non-blocking (continues even with errors)

**Example output:**
```
[TypeScript Hook] Type errors detected:
src/utils.ts:45:12 - error TS2322: Type 'string' is not assignable to type 'number'.
src/utils.ts:67:5 - error TS2339: Property 'foo' does not exist on type 'Bar'.
```

**Requirements:**
- TypeScript installed in project (`npm install typescript`)
- Valid `tsconfig.json` in project

---

### Prettier Auto-Formatter

**Location:** `optional-hooks/prettier/`

**What it does:**
1. Detects JS/TS file edits
2. Runs `npx prettier --write <file>`
3. Uses project's prettier config if available
4. Silently formats file

**Requirements:**
- Prettier installed in project or globally
- Optional: `.prettierrc` config in project

---

### Console.log Detector

**Location:** `optional-hooks/console-check/`

**What it does:**
1. Scans edited JS/TS files
2. Finds `console.log` statements
3. Shows first 5 occurrences with line numbers
4. Non-blocking warning

**Example output:**
```
[Console Hook] WARNING: console.log found in src/api.ts
45: console.log('Debug:', response);
78: console.log('User:', user);
[Console Hook] Remove console.log statements before committing
```

---

### Session Persistence

**Location:** `optional-hooks/session-persistence/`

**What it does:**
1. **On SessionStart**: Restores previous context
   - Shows previous git branch
   - Shows recently edited files
2. **On SessionEnd**: Saves current context
   - Saves git branch
   - Saves recently modified files (last 10)

**Example output (SessionStart):**
```
[Session] 📂 Restoring previous session context...
[Session] Previous branch: feature/payment-saga
[Session] Recently edited files:
  - src/payment/saga.ts
  - src/payment/events.ts
  - test/payment.test.ts
```

**Storage:** `~/.claude/team-session-state/`

---

### Git Push Reminder

**Location:** `optional-hooks/git-reminders/`

**What it does:**
1. Detects `git push` commands
2. Shows reminder to review changes
3. Suggests review commands
4. Non-blocking

**Example output:**
```
[Git Hook] 💡 Reminder: Review changes before pushing
[Git Hook] Run: git log --oneline -5 && git diff origin/$(git branch --show-current)
```

---

## Performance Comparison

| Hook | Performance Impact | Worth It? |
|------|-------------------|-----------|
| TypeScript Checker | ~1-2s per edit | ✅ Yes - catches errors early |
| Prettier | ~500ms per edit | ✅ Yes - consistent formatting |
| Console.log Detector | ~100ms per edit | ✅ Yes - very lightweight |
| Session Persistence | ~1s start/end | ✅ Yes - helpful context |
| Git Push Reminder | Instant | ⚠️ Optional - personal preference |

## Disabling Hooks

To disable a hook, remove its entry from `~/.claude/settings.json` or run:

```bash
./scripts/disable-hook.sh typescript
```

## Troubleshooting

### TypeScript checker not working

**Issue:** No errors shown despite type errors

**Solutions:**
1. Check TypeScript is installed: `npm list typescript`
2. Verify `tsconfig.json` exists in project
3. Test manually: `npx tsc --noEmit`

---

### Prettier not formatting

**Issue:** Files not auto-formatted

**Solutions:**
1. Check Prettier is installed: `npm list prettier`
2. Test manually: `npx prettier --write src/file.ts`
3. Check prettier config: `.prettierrc` or `package.json`

---

### Hooks causing slowness

**Issue:** Claude responses feel slow

**Solutions:**
1. Disable TypeScript checker (largest impact)
2. Disable Prettier formatter
3. Keep only console.log detector (minimal impact)

---

### Session persistence not working

**Issue:** Previous context not restored

**Solutions:**
1. Check directory exists: `~/.claude/team-session-state/`
2. Check permissions: `ls -la ~/.claude/team-session-state/`
3. Check state file: `cat ~/.claude/team-session-state/*.json`

## Best Practices

### ✅ Recommended Setup

For most engineers, enable these:
```bash
✅ TypeScript Type Checker
✅ Prettier Auto-Formatter
✅ Console.log Detector
✅ Session Persistence
```

### ⚠️ Performance-Conscious Setup

If you prioritize speed:
```bash
✅ Console.log Detector (fast)
✅ Session Persistence (only on start/end)
❌ TypeScript Checker (slow)
❌ Prettier (medium)
```

### 🎯 Quality-First Setup

If you prioritize code quality:
```bash
✅ TypeScript Type Checker
✅ Prettier Auto-Formatter
✅ Console.log Detector
✅ Session Persistence
✅ Git Push Reminder
```

## Feedback

These hooks are optional and can evolve based on team feedback. To suggest improvements:

1. Open issue in team-claude-config repo
2. Share feedback in #engineering-tools Slack
3. Submit PR with improvements

## Related Documentation

- [Complexity Assessment System](../docs/COMPLEXITY-ASSESSMENT.md)
- [Required Hooks](../hooks/) - Team-enforced hooks
- [Setup Guide](../docs/SETUP.md)
