---
name: chef:qa
description: Use when the user runs /chef:qa to review the IN_REVIEW slice before handing off to chef:fix or marking it DONE.
---

# QA — Slice Review

Review the `IN_REVIEW` slice in three phases: (1) build gate + completeness audit — run `pre-commit-checks.sh` and verify every scope bullet is implemented and tested; (2) execution trace — follow the code from entrypoint to exitpoint to build a thorough understanding of what the feature actually does before judging it; (3) implementation review — audit the diff for bugs, anti-patterns, and architecture deviations. Write a flat inline revision file if findings exist, or mark the slice `DONE` if clean.

**Findings describe problems, never solutions.** State what fails, why, where, and which files are affected. How to fix it is the job of `chef:fix`.

**File layout:** read `skills/shared/STRUCTURE.md` before touching any files.

---

## Step 1 — Guard

Read `sous-chef/CHECKPOINT`.

If CHECKPOINT is missing or `STATUS` is absent, stop:
```
No slice is IN_REVIEW. Run /chef:build to implement the active slice first.
```

Parse the three fields: `MILESTONE`, `SLICE`, `STATUS`.

If `STATUS` is not `IN_REVIEW`:
- `IN_PROGRESS` → `Slice {SLICE} is still in progress. Run /chef:build to finish it first.`
- `DONE` → `Slice {SLICE} is already DONE. Run /chef:refine to plan the next slice, or /chef:deliver if the milestone is complete.`

---

## Step 2 — Load context

Read silently — do not summarize to the user:

- `sous-chef/milestones/{MILESTONE}.md` — confirm the slice name
- `sous-chef/issues/{MILESTONE}/{SLICE}.md` — scope bullets, verification commands, branch name
- `sous-chef/ARCHITECTURE.md` — conventions the diff will be checked against

Note the slice name and branch from the issue frontmatter.

---

## Step 3 — Phase 1: Build gate + completeness audit

**Build gate:**

Run `pre-commit-checks.sh`. Capture the full output. Any tool failure (rubocop, rspec, brakeman, bundler-audit, database_consistency, strong_migrations) becomes a `BLOCKER` finding with the relevant output excerpt. Continue to the completeness audit regardless — do not stop on failure.

**Completeness audit:**

Read `git diff main...HEAD` and the scope bullets from the issue file. For each bullet verify:
- A corresponding code path exists
- An RSpec example exercises it (unless the bullet is purely visual layout with no behaviour)
- Test assertions can actually fail — not trivially true

A scope bullet with no code path → gap finding (`BLOCKER` or `HIGH` depending on whether it is load-bearing).  
A scope bullet with no RSpec coverage → `MED` finding.  
An always-passing assertion → `MED` finding.

Finding IDs use prefix `C` (e.g. `C1`, `C2`).

---

## Step 4 — Execution trace

Before reviewing any code for quality, build a thorough understanding of what the feature actually does. Trace the execution flow from the outermost entrypoint (route, job, webhook — wherever the slice is triggered) to every exitpoint (response, side effect, error path).

For each layer in the trace, note:
- What data enters, what decisions are made, what is returned or persisted
- Whether the behaviour matches the issue scope bullets
- Any branch or path the trace reveals that the scope does not account for

Produce a short internal trace summary (not shown to the user) covering:

1. **Entrypoint** — route, action, or trigger
2. **Flow** — ordered list of classes/methods called with a one-line description of what each does
3. **Exitpoints** — all terminal states (success response, error response, background job queued, etc.)
4. **Gaps observed** — anything the trace reveals that diverges from the issue scope

Use this trace as the foundation for Phase 2. Do not begin the implementation review until the trace is complete.

---

## Step 5 — Phase 2: Implementation review

Read `git diff main...HEAD`, then re-read every file the diff touches plus its spec file. Apply the understanding from the execution trace — deviations noticed during the trace are findings here.

Check against `ARCHITECTURE.md` conventions. Regardless of what ARCHITECTURE.md says, also check:

- Controllers stay thin — business logic belongs in service objects or models
- No N+1 queries where associations are traversed in views or serializers
- Authorization checks present on every non-public action
- No raw SQL strings where ActiveRecord scopes apply
- Errors not silently swallowed at system boundaries
- Test assertions that can actually fail

**Finding format rule:** describe what fails, why, and where. Name every affected file and line. Do not suggest a fix — that is `chef:fix`'s responsibility.

Finding IDs use prefix `I` (e.g. `I1`, `I2`).

---

## Step 6 — Write revision file (only if findings exist)

If both phases produced no findings, skip to Step 6.

**Determine revision number:** count existing `revision-*.md` files in `sous-chef/reviews/{MILESTONE}/{SLICE}/`. Next revision = count + 1. Create the directory if it does not exist.

Write `sous-chef/reviews/{MILESTONE}/{SLICE}/revision-N.md`:

```
---
branch: {branch from issue frontmatter}
revision: N
status: in_progress
milestone: "{MILESTONE}"
slice: "{SLICE}"
---

## Phase 1 — Build gate + completeness audit

<findings using flat inline format, or "No findings.">

## Phase 2 — Implementation review

<findings using flat inline format, or "No findings.">
```

**Flat inline finding format:**

```
**C1** · BLOCKER · OPEN · `app/models/article.rb`
RuboCop reports 3 offenses: frozen_string_literal missing (line 1), trailing whitespace (lines 4, 12).

**I1** · HIGH · OPEN · `app/controllers/articles_controller.rb:34`
`#destroy` has no authorization check. Any authenticated user can delete any record regardless of ownership. Affects `app/controllers/articles_controller.rb:34` and the corresponding request spec which does not assert the 403 case.
```

Findings state what is wrong and why — they do not prescribe a fix.

**Severities:** `BLOCKER · HIGH · MED · LOW`  
**Statuses:** `OPEN · FIXED · DISCARDED`

Do not touch CHECKPOINT, milestone file, or issue frontmatter — `chef:fix` takes over from here.

---

## Step 7 — Update status (clean pass only)

If both phases produced no findings, update in this order:

1. Issue frontmatter (`sous-chef/issues/{MILESTONE}/{SLICE}.md`): `status: IN_REVIEW` → `status: DONE`
2. Milestone file (`sous-chef/milestones/{MILESTONE}.md`): slice `STATUS: IN_REVIEW` → `STATUS: DONE`
   - If all slices in the milestone are now `DONE`: update milestone frontmatter `status: IN_PROGRESS` → `status: DONE`
3. CHECKPOINT (`sous-chef/CHECKPOINT`): `STATUS: IN_REVIEW` → `STATUS: DONE`

---

## Step 8 — Report

```
QA review complete — Slice {MILESTONE}/{SLICE} (Revision N)

Phase 1 — Build gate + completeness: <PASSED | N findings>
Phase 2 — Implementation review:     <PASSED | N findings>
Execution trace: complete

<if findings:>
Open findings (N total):
  C1 · BLOCKER — <summary>
  I1 · HIGH   — <summary>

Revision file: sous-chef/reviews/{MILESTONE}/{SLICE}/revision-N.md
Next step: /chef:fix to resolve findings, then /chef:qa again.

<if clean:>
Slice {SLICE} marked DONE.
<if pending slices remain:>  Next step: /chef:refine to plan the next slice.
<if milestone complete:>     Milestone {MILESTONE} complete. Next step: /chef:deliver.
```

Do not open a PR or commit. Do not advance CHECKPOINT to the next slice — the user drives the next step.
