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

Parse the three fields: `MILESTONE`, `SLICE`, `STATUS`.

If `STATUS` is not `IN_PROGRESS`:
- `IN_REVIEW` → `Slice {SLICE} is already built and awaiting review. Run /chef:qa to review it.`
- `DONE` → `Slice {SLICE} is DONE. Run /chef:refine to plan the next slice.`

---

## Step 2 — Read the issue plan

Open `sous-chef/issues/{MILESTONE}/{SLICE}.md`. Read the entire file — context, scope, schema changes, files to create/modify, test cases by name, implementation order, and verification commands.

The plan is the contract. Do not consult any other high-level document (PRD, ARCHITECTURE, milestone file) — everything needed to implement this slice must already be embedded in the plan. If it is not, stop and tell the user the plan is incomplete, naming what is missing, then suggest re-running `/chef:refine` to fill the gap.

Note the branch name from the frontmatter.

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

Follow the plan's **Implementation order** exactly — step by step, in numbered sequence. Do not reorder steps, skip steps, or batch multiple steps into one commit.

**Red-green cycle per step:**

1. Write the failing RSpec example(s) for the step.
2. Run specs inside Docker — confirm they fail (red). If they pass without implementation, the test is wrong; fix it before proceeding.
   ```bash
   docker compose exec web rspec {spec file path}
   ```
3. Write the minimum implementation to make them pass.
4. Run specs again — confirm they pass (green).
   ```bash
   docker compose exec web rspec {spec file path}
   ```

**Commit after each numbered step passes:**

```bash
git add <specific files>
git commit -m "feat({MILESTONE}/{SLICE}): <short description of step>"
```

Keep commits atomic. Stage only the files changed in that step.

---

## Step 7 — Final quality gate

> **CRITICAL — mandatory and non-negotiable:**
>
> Run `pre-commit-checks.sh` inside Docker. Every check must be green. Do not advance to Step 8 while any check is failing.

```bash
docker compose exec web pre-commit-checks.sh
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

The only valid exit from Step 7 is `pre-commit-checks.sh` exiting with status 0.

---

## Step 8 — Update status

> **CRITICAL — read before touching any status field:**
>
> Set status to `IN_REVIEW`. Never `DONE`. `DONE` is set exclusively by `chef:qa` after review.

Update in this order:

1. Issue file (`sous-chef/issues/{MILESTONE}/{SLICE}.md`) frontmatter: `status: IN_PROGRESS` → `status: IN_REVIEW`
2. Milestone file (`sous-chef/milestones/{MILESTONE}.md`): slice `STATUS: IN_PROGRESS` → `STATUS: IN_REVIEW`
3. CHECKPOINT (`sous-chef/CHECKPOINT`): `STATUS: IN_PROGRESS` → `STATUS: IN_REVIEW`

Commit the status updates together:

```bash
git add sous-chef/issues/{MILESTONE}/{SLICE}.md sous-chef/milestones/{MILESTONE}.md sous-chef/CHECKPOINT
git commit -m "chore({MILESTONE}/{SLICE}): mark slice IN_REVIEW"
```

---

## Step 9 — Handoff

```
Build complete — {MILESTONE}/{SLICE}

Implemented:
  <2–4 bullet summary of what was built>

Verification:
  <copy the Verification commands from the issue plan>

All checks pass. Slice is IN_REVIEW.
Next step: /chef:qa to review the implementation.
```

Do not open a PR. Do not run `/chef:qa` automatically. Hand off to the user.
