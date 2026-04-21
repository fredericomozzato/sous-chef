---
name: chef:fix
description: Use when open QA findings need to be resolved after /chef:qa has run on the current IN_REVIEW slice
---

# Fix — Resolve QA Findings

Work through all OPEN findings in the active revision file, highest severity first. Each finding is fixed, verified with `pre-commit-checks.sh`, then committed alongside the updated revision file. The revision is closed when all findings are FIXED or DISCARDED.

**Only the user may discard a finding.** The agent never suggests, offers, or autonomously marks anything as DISCARDED. If the user explicitly instructs the agent to discard a specific finding, follow the discard procedure in Step 5h. All other findings must be fixed.

**Announce at start:** "Using the fix skill to resolve open findings."

**File layout:** read `skills/shared/STRUCTURE.md` before touching any files.

---

## Step 1 — Guard

Read `sous-chef/CHECKPOINT`.

If CHECKPOINT is missing or `STATUS` is absent, stop:
```
No slice is active. Run /chef:refine to plan a slice first.
```

Parse `MILESTONE`, `SLICE`, `STATUS`.

If `STATUS` is not `IN_REVIEW`:
- `IN_PROGRESS` → `Slice {SLICE} is still in progress. Run /chef:build to finish it first.`
- `DONE` → `Slice {SLICE} is already DONE. Run /chef:refine to plan the next slice.`

---

## Step 2 — Find the active revision

List all files matching `sous-chef/reviews/{MILESTONE}/{SLICE}/revision-*.md`.

- If the directory does not exist → `No review directory found. Run /chef:qa first.`
- If no files found → `No revision files found. Run /chef:qa first.`

Read the frontmatter of each file. Find the one with `status: IN_PROGRESS` — that is the revision to fix.

If more than one has `status: IN_PROGRESS`, pick the highest-numbered one and warn the user:
```
Warning: multiple open revisions found. Using revision-N.md (highest-numbered).
The others may be from a browser-testing run on a previous build — review them manually if needed.
```

If none has `status: IN_PROGRESS`:
```
No active revision to fix. Run /chef:qa to create a new revision.
```

Read the active revision file in full.

---

## Step 3 — Parse OPEN findings

Scan the revision file for lines matching the flat inline format:

```
**ID** · SEVERITY · OPEN · `path`
```

For each OPEN finding collect:
- **ID** (e.g. `C1`, `I2`)
- **Severity** (`BLOCKER`, `HIGH`, `MED`, `LOW`)
- **Path** (the file reference on the header line)
- **Detail** (the paragraph immediately following the header line)

Ignore findings where the status field is `FIXED` or `DISCARDED`.

If no OPEN findings exist:
```
Nothing to fix — all findings are already FIXED or DISCARDED.
```
Stop.

---

## Step 4 — Sort and plan

Order by severity: `BLOCKER` → `HIGH` → `MED` → `LOW`.  
Within the same severity, preserve document order.

Create a todo for each finding in sorted order.

---

## Step 5 — Fix each finding

Repeat for each finding in order:

### a. Understand the change

Read the detail paragraph and every file it references. Understand the exact change required before touching any code.

### b. Write a failing test first (behavioral bugs only)

When the finding describes a **behavioral or functional bug** (wrong output, missing validation, incorrect state, logic error) — not a style, lint, or naming issue — write a failing RSpec example that reproduces the defect **before** touching the implementation.

The test must **fail on the current code** before proceeding. If it cannot be made to fail, the root cause is not yet understood — re-read the detail paragraph.

Skip this sub-step for findings with no behavioral component (pure RuboCop offenses, naming conventions, missing documentation).

### c. Implement the fix

Make the minimal change that resolves the finding. Do not:
- Refactor surrounding code
- Fix other issues noticed in passing (log them separately if needed)
- Add features or cleanups beyond the finding's scope

### d. Run `pre-commit-checks.sh` and iterate until green

```bash
pre-commit-checks.sh
```

If it fails, read the error output, diagnose the root cause, adjust the implementation, and run again. Repeat until all checks pass. There is no fixed attempt limit — keep iterating as long as progress is being made (each attempt gets closer to green or reveals new information).

Only escalate to the user if you are genuinely stuck: no remaining approaches, circular failures, or an error that requires a decision only the user can make. When escalating, report:

```
Stuck on [ID] — pre-commit-checks.sh still failing after N attempts.

<paste the relevant error output>

<explain what was tried and why it isn't working>

How would you like to proceed?
```

Do not mark the finding FIXED until `pre-commit-checks.sh` passes.

### e. Mark the finding FIXED in the revision file

Update the finding's header line — change `OPEN` to `FIXED`:

```
**I2** · MED · OPEN · `app/controllers/articles_controller.rb:34`
```
→
```
**I2** · MED · FIXED · `app/controllers/articles_controller.rb:34`
```

Do not change any other part of the document.

### f. If this is the last OPEN finding, close the revision

Update `status` in the revision file's frontmatter:
```yaml
status: DONE
```

### g. Commit this finding

**Commit immediately — before moving to the next finding.** Each finding is a separate commit. The revision file is already updated (FIXED status, and DONE if last), so the commit captures the full state.

Stage only the source files changed for this finding and the revision file. Commit message:

```
fix({MILESTONE}/{SLICE}): resolve [ID] — <one-line summary from finding>
```

Mark the todo for this finding complete. Move to the next finding.

### h. User-initiated discard (only when explicitly instructed)

If the user explicitly instructs you to discard a specific finding, do not attempt a fix. Instead:

1. Update the finding's header line — change `OPEN` to `DISCARDED`:
   ```
   **I2** · MED · DISCARDED · `app/controllers/articles_controller.rb:34`
   ```
2. Append a justification line immediately after the finding's description paragraph:
   ```
   *Discarded — {reason provided by user}*
   ```
3. If this is the last OPEN finding, close the revision (update frontmatter `status: DONE`).
4. Commit:
   ```
   chore({MILESTONE}/{SLICE}): discard [ID] — {one-line reason}
   ```

Never initiate or suggest a discard. Only act on an explicit user instruction naming the finding ID.

---

## Step 6 — Report

```
Fix complete — {MILESTONE}/{SLICE} (Revision N)

Fixed N findings:
  [C1] BLOCKER — <summary>
  [I1] HIGH    — <summary>

pre-commit-checks.sh passes. Revision status: DONE.
Next step: /chef:qa — a clean pass will mark the slice DONE.
```

If any finding was skipped because `pre-commit-checks.sh` failed, say so clearly and do not claim the revision is DONE.
