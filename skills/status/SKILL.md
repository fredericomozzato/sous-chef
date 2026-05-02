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
Tip: run /clear to free up context first.
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

Note: `STATUS: COMPLETE` occurs with no `SLICE` field present — this is a milestone-level marker, not a slice status. `STATUS: DONE` always has a `SLICE` field and refers to an individual slice being delivered.

| CHECKPOINT state | Last ran | Next step |
|---|---|---|
| `MILESTONE` only (no SLICE/STATUS) | `/chef:milestone` | `/chef:refine` |
| `STATUS: IN_PROGRESS` | `/chef:build` if `sous-chef/issues/{MILESTONE}/{SLICE}.md` exists, otherwise `/chef:refine` | `/chef:build` |
| `STATUS: IN_REVIEW` | `/chef:build` | `/chef:qa` |
| `STATUS: DONE` (SLICE present) | `/chef:qa` | `/chef:deliver` |
| `STATUS: COMPLETE` (no SLICE) | `/chef:deliver` | merge PR → `/chef:milestone` |

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
Tip: run /clear to free up context first.
```

Rules:
- Mark the active slice (matching CHECKPOINT's `SLICE` field) with `← active`. If no SLICE is set, no slice gets the marker.
- For `STATUS: COMPLETE`, next step spans two lines:
  ```
  Next step: merge the open PR
             then /chef:milestone
  Tip: run /clear to free up context first.
  ```
- Milestone STATUS for the header is derived from the milestone file's frontmatter `status` field, except: if CHECKPOINT has `STATUS: COMPLETE` (no SLICE), show `COMPLETE` in the header regardless of the frontmatter value.
