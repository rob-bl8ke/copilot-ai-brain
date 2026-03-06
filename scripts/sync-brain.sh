#!/usr/bin/env bash

set -euo pipefail

########################################
# Configuration
########################################

BRAIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# You may want to adjust this if your code repos are not in ~/code
CODE_ROOT="$HOME/code"

SKILLS_SOURCE="$BRAIN_ROOT/skills"
KNOWLEDGE_SOURCE="$BRAIN_ROOT/docs/temp/knowledge"

TARGET_CONFIG_DIR="$BRAIN_ROOT/targets"

DRY_RUN=false
DEBUG=false
TARGET_REPO_FILTER=""

########################################
# Parse arguments
########################################

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --debug)
      DEBUG=true
      shift
      ;;
    --repo)
      TARGET_REPO_FILTER="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1"
      exit 1
      ;;
  esac
done

########################################
# Debug helper
########################################

debug() {
  if [[ "$DEBUG" == true ]]; then
    echo "[DEBUG] $1"
  fi
}

########################################
# rsync setup
########################################

RSYNC_ARGS=(-av)

if [[ "$DRY_RUN" == true ]]; then
  RSYNC_ARGS+=(--dry-run)
fi

########################################
# Validation
########################################

if [[ ! -d "$SKILLS_SOURCE" ]]; then
  echo "ERROR: Skills directory not found"
  exit 1
fi

if [[ ! -d "$KNOWLEDGE_SOURCE" ]]; then
  echo "ERROR: Knowledge directory not found"
  exit 1
fi

debug "Brain root: $BRAIN_ROOT"
debug "Code root: $CODE_ROOT"

########################################
# Process targets
########################################

for config in "$TARGET_CONFIG_DIR"/*.conf; do

  source "$config"

  if [[ -n "$TARGET_REPO_FILTER" ]]; then
    CONFIG_NAME="$(basename "$config" .conf)"

    if [[ "$CONFIG_NAME" != "$TARGET_REPO_FILTER" ]]; then
      debug "Skipping $CONFIG_NAME due to --repo filter"
      continue
    fi
  fi

  echo
  echo "========================================"
  echo "Processing repo: $REPO_NAME"
  echo "========================================"

  TARGET_REPO="$CODE_ROOT/$REPO_NAME"

  if [[ ! -d "$TARGET_REPO" ]]; then
    echo "WARNING: Repo not found: $TARGET_REPO"
    continue
  fi

  TARGET_SKILLS="$TARGET_REPO/.github/skills"
  TARGET_KNOWLEDGE="$TARGET_REPO/docs/temp/knowledge"

  mkdir -p "$TARGET_SKILLS"
  mkdir -p "$TARGET_KNOWLEDGE"

  ########################################
  # Sync skills
  ########################################

  echo "Syncing skills"

  for skill in "${SKILLS[@]}"; do

    SRC="$SKILLS_SOURCE/$skill"
    DEST="$TARGET_SKILLS/$skill"

    if [[ ! -d "$SRC" ]]; then
      echo "  ✗ Skill missing: $skill"
      continue
    fi

    echo "  ✓ $skill"

    debug "  Source: $SRC"
    debug "  Dest  : $DEST"

    rsync "${RSYNC_ARGS[@]}" --delete "$SRC/" "$DEST/"
  done

  ########################################
  # Sync knowledge
  ########################################

  echo "Syncing knowledge"

  for file in "${KNOWLEDGE[@]}"; do

    SRC="$KNOWLEDGE_SOURCE/$file"
    DEST="$TARGET_KNOWLEDGE/$file"

    if [[ ! -f "$SRC" ]]; then
      echo "  ✗ Knowledge file missing: $file"
      continue
    fi

    echo "  ✓ $file"

    debug "  Source: $SRC"
    debug "  Dest  : $DEST"

    rsync "${RSYNC_ARGS[@]}" "$SRC" "$DEST"
  done

done

echo
echo "Sync complete."