---
name: chef:mise-en-place
description: Bootstrap the chef plugin and initialize the sous-chef project structure. Run once after installing the plugin.
---

# Mise en Place

Sets up everything needed to start using the chef workflow:
1. Merges the required Claude Code hook into `~/.claude/settings.json`
2. Creates the `sous-chef/` project structure in the current directory

Safe to run multiple times — existing configuration and files are preserved.

---

## Step 1 — Read the Current Global Settings

Read `~/.claude/settings.json`. If the file does not exist, treat its current content as `{}`.

## Step 2 — Check for Existing Hook

Check whether a `SessionStart` hook running `progress-load.sh` already exists:

```bash
jq -e '.hooks.SessionStart[]?.hooks[]? | select(.type == "command" and (.command | contains("progress-load.sh")))' ~/.claude/settings.json 2>/dev/null
```

- **Found** → skip to Step 4.
- **Not found** → proceed to Step 3.

## Step 3 — Merge the Hook

Resolve the full path to the script, then write it into the hook:

```bash
HOOK_PATH="$HOME/.claude/plugins/marketplaces/sous-chef/bin/progress-load.sh"
```

Add the `SessionStart` hook, preserving all existing settings:

```bash
jq --arg cmd "$HOOK_PATH" '.hooks.SessionStart += [{"hooks": [{"type": "command", "command": $cmd, "timeout": 10}]}]' ~/.claude/settings.json
```

Write the result back to `~/.claude/settings.json`. Validate after writing:

```bash
jq -e '.hooks.SessionStart[]?.hooks[]? | select(.type == "command" and (.command | contains("progress-load.sh")))' ~/.claude/settings.json
```

Exit code 0 = hook is present. Any other exit = report the error and stop.

## Step 4 — Create the Project Structure

Run the init script to create the `sous-chef/` folder and template files. The script is on PATH via the plugin's `bin/` directory — do not construct a path to it:

```bash
mise-en-place.sh
```

## Step 5 — Confirm to User

Report both outcomes together:

```
Mise en place complete.

Claude Code hook: <added to ~/.claude/settings.json | already configured>
  SessionStart → progress-load.sh (auto-loads session context)

sous-chef/ structure: <created | already exists>
  sous-chef/PRD.md
  sous-chef/ARCHITECTURE.md
  sous-chef/milestones/
  sous-chef/issues/
  sous-chef/reviews/

Next steps:
  1. Restart Claude Code (or open /hooks) to activate the session hook
  2. Run /chef:interview to plan your features
```
