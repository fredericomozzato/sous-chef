---
name: chef:refine
description: Use when the user runs /chef:refine to expand the next pending slice into a full implementation plan.
---

# Refine — Slice Planning

Identify the next PENDING slice in the active milestone, survey the codebase, draft a detailed Rails implementation plan, get user approval, then write the issue file and advance the slice status.

**File layout:** read `skills/shared/STRUCTURE.md` before touching any files.

---

## Step 1 — Sync main

Ensure we are on `main` with the latest changes before any planning:

```bash
git checkout main && git pull origin main
```

## Step 2 — Guard

Read `sous-chef/CHECKPOINT`.

**No CHECKPOINT (or file missing), or CHECKPOINT has `STATUS: COMPLETE`:**
- List `sous-chef/milestones/` for any file whose frontmatter contains `status: PENDING`
- If found, ask: *"No milestone is active. Want me to activate {NNN-slug} so we can start refining slices?"*
  - If yes: write CHECKPOINT (`MILESTONE: {NNN-slug}` — no SLICE or STATUS yet), set milestone `status: PENDING → IN_PROGRESS`, continue to Step 3
  - If no: stop
- If none found: stop — `No active or pending milestones. Run /chef:milestone first.`

**CHECKPOINT exists with active work — parse it:**

CHECKPOINT may have one line (milestone only) or three lines (milestone + slice + status). Extract:
- `MILESTONE:` → the active milestone slug (always present)
- `SLICE:` → the active slice number (absent if no slice has been refined yet)
- `STATUS:` → current slice status (absent if no slice has been refined yet)

Open `sous-chef/milestones/{milestone-slug}.md`:
- If milestone `status: DONE`: stop — `Milestone {NNN-slug} is complete. Run /chef:milestone to start the next one.`
- If no PENDING slices remain (all are IN_PROGRESS, IN_REVIEW, or DONE): stop and report each slice's current status. Suggest `/chef:build` or `/chef:qa` as appropriate.

## Step 3 — Read context

Read silently — do not summarize to the user:
- `sous-chef/PRD.md`
- `sous-chef/ARCHITECTURE.md`
- `sous-chef/milestones/{NNN-slug}.md`

Note the active milestone's ID (`NNN`) and slug. Find the **first** slice with `STATUS: PENDING`. Note its number, name, and scope bullets.

## Step 4 — Survey the codebase

Identify files the slice will create or extend based on the scope bullets. Read:
- Existing models, controllers, views, and jobs relevant to the slice
- Migration files to understand current schema
- Established RSpec patterns in `spec/` (factories, shared examples, request vs. system specs)
- Any service objects, policies, or helpers the slice will interact with

Goal: understand what already exists so the plan extends rather than duplicates.

## Step 5 — Draft behavioral specs

Using the scope bullets as input, write the Gherkin scenarios that define the observable behavior of this slice.

**Rules:**

- Cover the happy path and every key edge case (invalid input, missing auth, boundary conditions)
- Describe what a user sees or what the system returns — never internal class calls or ActiveRecord details
- One scenario per distinct behavior; do not bundle multiple outcomes into one scenario
- Keep scenario names short enough to become RSpec example descriptions verbatim

```gherkin
# Good — observable, user-facing
Scenario: Submit valid recipe form
  GIVEN I am logged in as a chef
  WHEN I submit the new recipe form with valid data
  THEN the recipe appears in my recipe list
  AND I see "Recipe created"

# Bad — describes implementation
Scenario: RecipesController create action
  GIVEN valid params are posted to RecipesController#create
  WHEN ActiveRecord saves the record
  THEN the response status is 302
```

## Step 6 — Present specs for approval

Show only the behavioral specs. Ask:

> "Do these scenarios cover the expected behavior? Any changes, additions, or removals before I draft the implementation plan?"

Revise and re-present until the user explicitly approves. **Do not draft implementation details until the specs are approved.**

## Step 7 — Draft the implementation plan

With approved specs in hand, produce the remaining plan sections:

| Section | Content |
|---------|---------|
| **Context** | What has been built; how this slice connects to prior work |
| **Scope** | Exact deliverables from the milestone slice bullets |
| **Behavioral specs** | The approved Gherkin scenarios (copied verbatim) |
| **Schema changes** | Migration details — table name, columns, types, constraints, indexes. Omit if no DB changes |
| **Files to create/modify** | One subsection per file: path, purpose, key class/method signatures, SQL patterns if applicable |
| **RSpec tests** | One subsection per spec file: each example by name and what it verifies — derived directly from the behavioral specs |
| **Implementation order** | One step per scenario: write spec → red → implement → green → commit. Each step is named after its scenario. Schema migrations and any required setup (factories, routes) come first as unnumbered prerequisites before the scenario steps begin. |
| **Verification** | Exact commands and expected output to confirm the slice is done |

The RSpec tests section must map one-to-one with the scenarios: each scenario becomes one or more named examples. No RSpec example may exist without a corresponding scenario, and no scenario may be left without a covering example.

**Rails conventions from ARCHITECTURE.md apply without exception.** Honour whatever the user's project documents there.

**Quality bar:** every file section must include concrete method signatures; every test section must list each example by name. Vague entries are not acceptable.

**Branch name:** `feat/{milestone-slug}/{slice-NNN}-{slice-slug}` (e.g. `feat/oauth-authentication/002-google-oauth-provider`)

## Step 8 — Present plan for approval

Show the full plan. Ask:

> "Does this plan look good? Any changes before I write it to the issue file?"

Revise and re-present until the user explicitly approves. Do not write any file before approval.

## Step 9 — Finalize

On approval, in this order:

1. Create directory `sous-chef/issues/{NNN-slug}/` if it does not exist.

2. Write the plan to `sous-chef/issues/{NNN-slug}/{slice-NNN}.md` with this frontmatter:
   ```yaml
   ---
   status: IN_PROGRESS
   branch: feat/{milestone-slug}/{slice-NNN}-{slice-slug}
   slice: "{slice-NNN}"
   milestone: "{NNN-slug}"
   ---
   ```

3. In `sous-chef/milestones/{NNN-slug}.md`, update the slice:
   `STATUS: PENDING` → `STATUS: IN_PROGRESS`

4. Overwrite `sous-chef/CHECKPOINT` with the full three-line format:
   ```
   MILESTONE: {NNN-slug}
   SLICE: {slice-NNN}
   STATUS: IN_PROGRESS
   ```

Do NOT commit. Do NOT switch branches. This step is planning only.

## Step 10 — Report

```
Slice {milestone-NNN}/{slice-NNN} — {slice name}

  Plan written to: sous-chef/issues/{NNN-slug}/{slice-NNN}.md
  Branch:          feat/{milestone-slug}/{slice-NNN}-{slice-slug}

  Milestone progress: {X}/{total} slices PENDING

Next step: /chef:build to implement this slice.
```
