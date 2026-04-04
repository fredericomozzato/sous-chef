#!/usr/bin/env bash
# SessionStart hook: injects latest handoff context into the new session.
# Writes session metadata to a temp file so /chef:handoff can find the session_id.

# Read hook input from stdin
INPUT=$(cat 2>/dev/null || echo '{}')

# Extract session_id
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""' 2>/dev/null || echo "")

# Get project and branch
PROJECT=$(basename "$(pwd)" 2>/dev/null || echo "")
BRANCH=$(git branch --show-current 2>/dev/null || echo "")

# Bail if not in a git repo or can't determine context
[ -z "$PROJECT" ] || [ -z "$BRANCH" ] && exit 0

# Clean branch name for filesystem use (replace / with -)
BRANCH_CLEAN=$(echo "$BRANCH" | tr '/' '-')

# Progress directory for this project + branch
PROGRESS_DIR="$HOME/.claude/progress/$PROJECT/$BRANCH_CLEAN"
mkdir -p "$PROGRESS_DIR" 2>/dev/null || true

# Write session metadata to temp file so /chef:handoff can look it up
echo "{\"session_id\":\"$SESSION_ID\",\"project\":\"$PROJECT\",\"branch\":\"$BRANCH\",\"branch_clean\":\"$BRANCH_CLEAN\",\"progress_dir\":\"$PROGRESS_DIR\"}" \
  > "/tmp/.chef-session-$PROJECT-$BRANCH_CLEAN" 2>/dev/null || true

# Find the latest session file
LATEST=$(ls "$PROGRESS_DIR"/session-*.md 2>/dev/null | sort -V | tail -1)

# No previous session — exit silently, nothing to inject
[ -z "$LATEST" ] && exit 0

CONTENT=$(cat "$LATEST" 2>/dev/null || echo "")
[ -z "$CONTENT" ] && exit 0

SESSION_NUM=$(basename "$LATEST" .md | sed 's/session-//')

# Output JSON with additionalContext — injected directly into model context
jq -n \
  --arg content "$CONTENT" \
  --arg session "Session $SESSION_NUM" \
  --arg branch "$BRANCH" \
  '{
    hookSpecificOutput: {
      hookEventName: "SessionStart",
      additionalContext: ("=== HANDOFF CONTEXT (" + $session + " / " + $branch + ") ===\n" + $content + "\n=== END HANDOFF CONTEXT ===")
    }
  }'
