---
name: chef:handoff
description: Save a session handoff snapshot before ending a session. Creates or updates a progress file scoped to the current project, branch, and session. Auto-loads on next session start via the SessionStart hook.
---

# Handoff Skill

**User-only command.** Never invoke this skill autonomously. It is triggered explicitly by the developer to capture session state before stepping away.

## What This Does

Creates or updates a handoff file at:
```
~/.claude/progress/{project}/{branch}/session-NNN.md
```

Running it multiple times in the same Claude Code session updates the same file. Starting a new session and running it creates the next numbered file.

On the next session start, the file is injected automatically via the `SessionStart` hook — no manual action needed.

---

## Step 1 — Gather Session Metadata

Run these commands:

```bash
PROJECT=$(basename "$(pwd)")
BRANCH=$(git branch --show-current)
BRANCH_CLEAN=$(echo "$BRANCH" | tr '/' '-')
PROGRESS_DIR="$HOME/.claude/progress/$PROJECT/$BRANCH_CLEAN"
```

Then read the temp file written by the SessionStart hook to get the session_id:

```bash
cat "/tmp/.chef-session-$PROJECT-$BRANCH_CLEAN" 2>/dev/null
```

If the temp file is missing (e.g. first-ever session, or hook not configured), set `SESSION_ID=""`.

---

## Step 2 — Determine the Target File

Check whether a session file already exists for this session:

```bash
grep -rl "session_id: \"$SESSION_ID\"" "$PROGRESS_DIR"/session-*.md 2>/dev/null | head -1
```

- **Match found** → update that file in place (preserve `created_at`, increment `updated_at`)
- **No match or empty SESSION_ID** → create the next numbered file:

```bash
LAST=$(ls "$PROGRESS_DIR"/session-*.md 2>/dev/null | sort -V | tail -1 | xargs -I{} basename {} .md | sed 's/session-//' 2>/dev/null || echo "000")
NEXT=$(printf "%03d" $((10#$LAST + 1)))
TARGET="$PROGRESS_DIR/session-$NEXT.md"
mkdir -p "$PROGRESS_DIR"
```

---

## Step 3 — Gather Git Context

```bash
git log $(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null | sed 's|origin/||' || echo "main")..HEAD --oneline 2>/dev/null | head -30
git diff $(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null | sed 's|origin/||' || echo "main") --stat 2>/dev/null | tail -20
git status --short 2>/dev/null
```

If the target file already exists, read it — it contains the prior summary to build on.

---

## Step 4 — Dispatch Summarization Sub-agent

Dispatch a Haiku sub-agent (`claude-haiku-4-5-20251001`) with the following prompt. Pass all gathered context inline.

---

**Sub-agent prompt:**

```
You are a session summarization agent. Write a handoff file for a development session.

STRICT RULES — READ BEFORE ANYTHING ELSE:
- The output file MUST NOT exceed 100 lines (including frontmatter, headers, blank lines — everything).
- Be ruthlessly concise. Cut from Done and Todo first if over budget.
- Do not explain, pad, or add context that isn't directly actionable.
- Write only what a developer needs to pick up the work cold.

INPUT:
- Target file path: {TARGET}
- Session ID: {SESSION_ID}
- Project: {PROJECT}
- Branch: {BRANCH}
- Session number: {SESSION_NUM}
- Now (ISO 8601): {TIMESTAMP}
- Existing file content (empty if new): {EXISTING_CONTENT}
- Git log: {GIT_LOG}
- Git diff stat: {GIT_DIFF_STAT}
- Git status: {GIT_STATUS}

Write the file to {TARGET} using exactly this structure:

---
session_id: "{SESSION_ID}"
project: {PROJECT}
branch: {BRANCH}
session: "{SESSION_NUM}"
created_at: {CREATED_AT}
updated_at: {TIMESTAMP}
status: IN_PROGRESS
---

# Session {SESSION_NUM} — {BRANCH}

## Goal
[1–2 sentences: what this branch is trying to achieve and why]

## Done
[Bullet list of completed work. Use git log as the primary source. Each item one line.]

## In Progress
[What was actively being worked on when handoff was triggered. Max 3 bullets.]

## Todo
[Remaining work not yet started. Each item one line.]

## Key Files
[Only files central to this branch's changes — derived from git diff stat]
- `path/to/file` — [one phrase describing its role]

## Notes
[Critical context only: decisions made, gotchas, open questions, things the next agent must know. This section matters most — do not cut it to save lines. Cut Done/Todo instead.]

LINE BUDGET:
  Frontmatter:   ~10 lines
  Goal:            2–3 lines
  Done:          max 20 lines
  In Progress:    max 5 lines
  Todo:          max 15 lines
  Key Files:     max 10 lines
  Notes:         max 15 lines
  Headers/gaps:  ~10 lines
  TOTAL:        ≤ 100 lines

IMPORTANT: If updating an existing file, preserve the original created_at value.
Write the file using the Write tool. Do not output the content — write it directly to {TARGET}.
```

---

## Step 5 — Confirm to User

After the sub-agent writes the file, confirm:

```
Handoff saved → {TARGET}
Session {SESSION_NUM} / {PROJECT} / {BRANCH}
```

---

## Hook Setup

To enable automatic context loading on session start, add the following to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "progress-load.sh",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

`progress-load.sh` is on PATH automatically when the `chef` plugin is enabled.
