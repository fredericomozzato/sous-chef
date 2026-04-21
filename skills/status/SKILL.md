---
name: chef:status
description: Use when the user runs /chef:status to see a summary of the active milestone, slice progress, and what command to run next.
---

# Status — Milestone Report

Read CHECKPOINT and the active milestone file. Print a concise report of what has been done and what is open, ending with a single next-step command.

**Announce at start:** "Using the status skill to report milestone progress."

Read-only. Never writes or commits anything.

---

## Step 1 — Read CHECKPOINT

Read `sous-chef/CHECKPOINT`.

**If CHECKPOINT is missing**, print and stop:

```
No active milestone.
Next step: /chef:milestone
```

Parse the fields:
- `MILESTONE` — always present if file exists
- `SLICE` — absent if no slice has been refined yet
- `STATUS` — absent if no slice has been refined yet

---

## Step 2 — Read the milestone file

Open `sous-chef/milestones/{MILESTONE}.md`.

For each slice, record its number, name, and STATUS. Count total slices and DONE slices.

---

## Step 3 — Determine last ran / next step

Apply this mapping based on the CHECKPOINT state:

| CHECKPOINT state | Last ran | Next step |
|---|---|---|
| `MILESTONE` only (no SLICE/STATUS) | `/chef:milestone` | `/chef:refine` |
| `STATUS: IN_PROGRESS` | `/chef:refine` or `/chef:build` | `/chef:build` |
| `STATUS: IN_REVIEW` | `/chef:build` | `/chef:qa` |
| `STATUS: DONE` | `/chef:qa` | `/chef:deliver` |
| `STATUS: COMPLETE` | `/chef:deliver` | merge PR → `/chef:milestone` |

---

## Step 4 — Report

Print using this format:

```
Milestone: {MILESTONE} — {milestone STATUS} ({DONE count}/{total} slices)

  {NNN} — {slice name}    {STATUS}  ← active
  {NNN} — {slice name}    {STATUS}
  ...

Last ran:  {last ran}
Next step: {next step}
```

Rules:
- Mark the active slice (matching CHECKPOINT's `SLICE` field) with `← active`. If no SLICE is set, no slice gets the marker.
- For `STATUS: COMPLETE`, next step spans two lines:
  ```
  Next step: merge the open PR
             then /chef:milestone
  ```
- Milestone STATUS for the header is derived from the milestone file's frontmatter `status` field.
