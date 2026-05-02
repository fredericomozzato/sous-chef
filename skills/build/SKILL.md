---
name: chef:build
description: Use when the user runs /chef:build to implement the IN_PROGRESS slice from the issue plan.
---

# Build — Slice Implementation

Implement the `IN_PROGRESS` slice. The issue plan is the only contract — it is assumed to be complete and correct. No other high-level documents are loaded.

**Announce at start:** "Using the build skill to implement the current IN_PROGRESS slice."

**File layout:** read `skills/shared/STRUCTURE.md` before touching any files.

---

## Step 1 — Guard

Read `sous-chef/CHECKPOINT`.

If CHECKPOINT is missing or `STATUS` is absent, stop:
```
No slice is IN_PROGRESS. Run /chef:refine to plan a slice first.
```

Parse all fields: `MILESTONE`, `SLICE`, `STATUS`, and `STEP` (optional — absent on a fresh build).

If `STATUS` is not `IN_PROGRESS`:
- `IN_REVIEW` → `Slice {SLICE} is already built and awaiting review. Run /chef:qa to review it.`
- `DONE` → `Slice {SLICE} is DONE. Run /chef:refine to plan the next slice.`

If `STEP` is present, note the last completed step number — the build will resume from the next step.

---

## Step 2 — Read the issue plan

Open `sous-chef/issues/{MILESTONE}/{SLICE}.md`. Read the entire file — context, scope, schema changes, files to create/modify, test cases by name, implementation order, and verification commands.

The plan is the contract. Do not consult any other high-level document (PRD, ARCHITECTURE, milestone file) — everything needed to implement this slice must already be embedded in the plan. If it is not, stop and tell the user the plan is incomplete, naming what is missing, then suggest re-running `/chef:refine` to fill the gap.

Note the branch name from the frontmatter.

Count and note every numbered step in the **Implementation order** section. Prerequisites (unnumbered setup tasks before step 1) are labeled `P1`, `P2`, etc.

---

## Step 3 — Survey the codebase

Read only the files the plan explicitly names under "files to create/modify". For each file that already exists, read it to confirm:
- Method signatures and class names match the plan's assumptions
- Any interface the plan calls into is still present and unchanged

Do not read files the plan does not mention. Do not read the full codebase speculatively.

---

## Step 4 — Validate the plan

Before touching any code, check for:

- **Blockers** — plan references a class, method, or constant that does not exist yet
- **Divergence** — current code has drifted from the plan (renamed fields, changed signatures, removed files)
- **Ambiguity** — a numbered step is too vague to execute safely

If any issue is found, stop. Describe each problem precisely (file, line, what the plan expects vs. what exists). Tell the user to update the issue plan or re-run `/chef:refine` to resolve the gap.

**Do not begin implementation until the plan is fully sound.**

---

## Step 5 — Checkout the feature branch

Branch name is in the issue frontmatter: `branch: feat/{milestone-slug}/{slice-NNN}-{slice-slug}`.

```bash
git branch --show-current
```

If already on the correct branch, proceed. Otherwise:

```bash
# Ensure main is up to date before cutting a new branch
git checkout main && git pull origin main
git checkout -b {branch}
```

If the branch already exists remotely or locally, check it out directly without pulling main:

```bash
git checkout {branch}
```

Never implement on `main`.

---

## Step 6 — Commit planning files

`chef:milestone` and `chef:refine` write planning files on `main` without committing — those unstaged changes travel to this branch when it is created. Commit them now, before any implementation begins:

```bash
git add sous-chef/CHECKPOINT sous-chef/milestones/{MILESTONE}.md sous-chef/issues/{MILESTONE}/{SLICE}.md
git commit -m "chore({MILESTONE}/{SLICE}): plan slice"
```

If the branch already existed and was checked out directly (no fresh creation from main), skip this step — the planning files were committed in a prior session.

---

## Step 7 — Implement with TDD

### Determine the starting point

Check the `STEP` value read from CHECKPOINT in Step 1:

- **`STEP` is absent** — fresh build. Start from the first prerequisite (if any), then step 1.
- **`STEP` is `P{N}`** — prerequisites were partially completed. Resume from prerequisite `P{N+1}`, or step 1 if all prerequisites are done.
- **`STEP` is a number** — that step is complete. Resume from step `{N+1}`.

Announce the starting point:
- Fresh: `"Starting implementation from the beginning."`
- Resuming: `"Resuming from step {next step} — steps {completed list} already done."`

Do not re-implement or re-commit completed steps. Git history is the ground truth — if a step's commit exists, it is done.

### Prerequisites

Handle any prerequisites (migrations, factories, routes) listed before the numbered steps first. For each prerequisite `P{N}`:

1. Execute the prerequisite task.
2. Commit: `git commit -m "chore({MILESTONE}/{SLICE}): <description>"`
3. Update CHECKPOINT immediately after the commit — add or update the `STEP` line:
   ```
   MILESTONE: {MILESTONE}
   SLICE: {SLICE}
   STATUS: IN_PROGRESS
   STEP: P{N}
   ```
   ```bash
   git add sous-chef/CHECKPOINT
   git commit -m "chore({MILESTONE}/{SLICE}): checkpoint P{N}"
   ```

### Red-green cycle — one scenario per numbered step, no exceptions

For each numbered step in the implementation order:

1. Write the RSpec example for this step's scenario only. Use the scenario name verbatim as the example description. Assert the THEN clause directly. Do not write examples for future steps.
2. Run specs — confirm this example fails (red). If it passes without implementation, the test is wrong; fix it before proceeding.
   ```bash
   docker compose exec web rspec {spec file path}
   ```
3. Write the minimum implementation to make this example pass. Do not implement anything beyond what this scenario requires.
4. Run specs — confirm this example passes (green) and no previously passing examples regressed.
   ```bash
   docker compose exec web rspec {spec file path}
   ```
5. Commit the implementation.
   ```bash
   git add <specific files>
   git commit -m "feat({MILESTONE}/{SLICE}): <scenario name>"
   ```
6. Update CHECKPOINT immediately after the commit — add or update the `STEP` line with the completed step number:
   ```
   MILESTONE: {MILESTONE}
   SLICE: {SLICE}
   STATUS: IN_PROGRESS
   STEP: {N}
   ```
   ```bash
   git add sous-chef/CHECKPOINT
   git commit -m "chore({MILESTONE}/{SLICE}): checkpoint step {N}"
   ```

Never carry uncommitted work into the next scenario. Never skip the CHECKPOINT update after a commit.

---

## Step 8 — Final quality gate

> **CRITICAL — mandatory and non-negotiable:**
>
> Run `pre-commit-checks.sh`. Every check must be green. Do not advance to Step 9 while any check is failing.

Run the script. It is on PATH via the plugin's `bin/` directory — do not construct a path to it:

```bash
pre-commit-checks.sh  # on PATH via plugin bin/
```

If anything fails:
1. Read the failure output carefully.
2. Fix the root cause — do not suppress warnings or use `# rubocop:disable` to paper over issues.
3. Re-run `pre-commit-checks.sh` from scratch.
4. Repeat until all checks pass.

**Red flags — stop if you think any of these:**
- "The offense is minor, I'll proceed anyway"
- "Tests pass, the lint failure is just style"
- "I'll note the failure and move on"

The only valid exit from Step 8 is `pre-commit-checks.sh` exiting with status 0.

---

## Step 9 — Update status

> **CRITICAL — read before touching any status field:**
>
> Set status to `IN_REVIEW`. Never `DONE`. `DONE` is set exclusively by `chef:qa` after review.

Update in this order:

1. Issue file (`sous-chef/issues/{MILESTONE}/{SLICE}.md`) frontmatter: `status: IN_PROGRESS` → `status: IN_REVIEW`
2. Milestone file (`sous-chef/milestones/{MILESTONE}.md`): slice `STATUS: IN_PROGRESS` → `STATUS: IN_REVIEW`
3. CHECKPOINT (`sous-chef/CHECKPOINT`): set `STATUS: IN_REVIEW` and **remove the `STEP` line entirely** — it is only meaningful during an active build.

   Final CHECKPOINT format after build:
   ```
   MILESTONE: {MILESTONE}
   SLICE: {SLICE}
   STATUS: IN_REVIEW
   ```

Commit the status updates together:

```bash
git add sous-chef/issues/{MILESTONE}/{SLICE}.md sous-chef/milestones/{MILESTONE}.md sous-chef/CHECKPOINT
git commit -m "chore({MILESTONE}/{SLICE}): mark slice IN_REVIEW"
```

---

## Step 10 — Handoff

```
Build complete — {MILESTONE}/{SLICE}

Implemented:
  <2–4 bullet summary of what was built>

Verification:
  <copy the Verification commands from the issue plan>

All checks pass. Slice is IN_REVIEW.
Next step: /chef:qa to review the implementation.
Tip: run /clear to free up context first.
```

Do not open a PR. Do not run `/chef:qa` automatically. Hand off to the user.
