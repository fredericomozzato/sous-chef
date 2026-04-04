---
name: setup
description: Bootstrap the chef plugin. Merges required hooks into ~/.claude/settings.json so plugin features work automatically. Run once after installing the plugin.
---

# Setup Skill

Configures the `chef` plugin by merging required settings into `~/.claude/settings.json`. Safe to run multiple times — existing configuration is preserved.

## What This Configures

| Feature | Mechanism | Effect |
|---|---|---|
| Auto-load handoff context | `SessionStart` hook | Injects previous session file at session start |

---

## Step 1 — Read the Current Global Settings

Read `~/.claude/settings.json`. If the file does not exist, treat its current content as `{}`.

## Step 2 — Check for Existing Hook

Check whether a `SessionStart` hook running `progress-load.sh` already exists:

```bash
jq -e '.hooks.SessionStart[]?.hooks[]? | select(.type == "command" and (.command | contains("progress-load.sh")))' ~/.claude/settings.json 2>/dev/null
```

- **Found** → skip to Step 4, nothing to change.
- **Not found** → proceed to Step 3.

## Step 3 — Merge the Hook

Add the `SessionStart` hook, preserving all existing settings. Use `jq` to merge:

```bash
jq '.hooks.SessionStart += [{"hooks": [{"type": "command", "command": "progress-load.sh", "timeout": 10}]}]' ~/.claude/settings.json
```

If `.hooks` or `.hooks.SessionStart` does not exist yet, `+=` initialises them correctly.

Write the result back to `~/.claude/settings.json` using the Edit tool (or Write if the file did not exist).

Validate the JSON after writing:

```bash
jq -e '.hooks.SessionStart[]?.hooks[]? | select(.type == "command" and (.command | contains("progress-load.sh")))' ~/.claude/settings.json
```

Exit code 0 = hook is present. Any other exit = something went wrong — report the error to the user and stop.

## Step 4 — Confirm to User

If hook was already present:
```
chef plugin already configured — no changes needed.
```

If hook was added:
```
chef plugin configured.

Added to ~/.claude/settings.json:
  SessionStart hook → progress-load.sh (auto-loads handoff context)

Restart Claude Code or open /hooks to activate.
```
