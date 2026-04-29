---
name: chef:deliver
description: Use when the user runs /chef:deliver to ship the completed slice — verifies the slice is DONE with no open QA findings, runs pre-commit-checks, writes and creates a PR for the slice, then advances CHECKPOINT so the next slice can begin.
---

# Deliver — Slice Delivery Gate

Ship the completed slice as a PR. A milestone may require multiple `deliver` runs — one per slice. This skill checks whether the milestone is fully done after the slice ships and updates CHECKPOINT accordingly.

**Announce at start:** "Using the deliver skill to ship the current slice."

**File layout:** read `skills/shared/STRUCTURE.md` before touching any files.

---

## Step 1 — Guard: CHECKPOINT

Read `sous-chef/CHECKPOINT`.

If the file is missing, stop:
```
No active milestone. Run /chef:milestone to start one.
```

Parse the fields. If `MILESTONE` is absent, stop:
```
CHECKPOINT is malformed — no MILESTONE value found.
```

If `SLICE` or `STATUS` are absent, stop:
```
No slice has been refined yet. Run /chef:refine to plan the first slice.
```

If `STATUS` is not `DONE`:
- `IN_PROGRESS` → `Slice {SLICE} is still in progress. Run /chef:build to finish it first.`
- `IN_REVIEW` → `Slice {SLICE} is awaiting QA. Run /chef:qa first.`

Record `MILESTONE` and `SLICE` for use in subsequent steps.

---

## Step 2 — Guard: no open QA revisions

List all files matching `sous-chef/reviews/{MILESTONE}/{SLICE}/revision-*.md`.

For each file found, read its frontmatter `status` field. If any revision has `status: IN_PROGRESS`, stop:

```
There are open QA findings that must be resolved before delivering:

  sous-chef/reviews/{MILESTONE}/{SLICE}/revision-N.md — IN_PROGRESS

Run /chef:fix to resolve all findings, then /chef:qa for a clean pass.
```

Proceed only when every revision file for this slice has `status: DONE`, or there are no revision files at all.

---

## Step 3 — Final quality gate

All checks run inside Docker.

**3a — Pre-commit checks:**

```bash
pre-commit-checks.sh  # on PATH via plugin bin/
```

If any check fails, stop immediately. Do not attempt to fix anything. Report the failures to the user:

```
Delivery blocked — pre-commit-checks.sh failed.

Failed checks:
  {tool name}: {summary of what failed}
  {tool name}: {summary of what failed}

Relevant output:
  {paste the failing section of the output — enough context to locate the problem}

Fix the issues above and re-run /chef:deliver when ready.
```

The only valid exit from Step 3a is the command returning status 0.

**3b — Bundler audit:**

```bash
docker compose exec web bundle exec bundler-audit check --update
```

If any vulnerabilities are found, this is a **hard block** — stop immediately:

```
Delivery blocked — bundler-audit found vulnerabilities.

{gem name} {version}: {advisory summary}
Advisory: {CVE or URL}

Resolve the vulnerabilities (bump the affected gems) and re-run /chef:deliver.
```

Do not proceed to Step 4 while any CVE is open.

---

## Step 4 — Note the feature branch

Run:

```bash
git branch --show-current
```

Record the branch name. Also read the issue frontmatter at `sous-chef/issues/{MILESTONE}/{SLICE}.md` to confirm the branch matches the `branch:` field. Proceed either way — report a mismatch if found but do not stop.

---

## Step 5 — Check for UI changes

Read `sous-chef/issues/{MILESTONE}/{SLICE}.md` and scan the scope bullets for any mention of views, templates, forms, Turbo Streams, Stimulus controllers, or other browser-visible output.

**If UI changes are present:** read `skills/deliver/resources/screenshot-flow.md` and follow it before proceeding to Step 6. Screenshots must be captured and saved before the PR description is drafted.

**If no UI changes:** proceed directly to Step 6.

---

## Step 6 — Draft and save the PR description

Read `skills/deliver/resources/pr-template.md` for authoring rules, title format, and the two-section structure (`Summary` + `Test Plan`).

Read `sous-chef/issues/{MILESTONE}/{SLICE}.md` to source both sections:

- **Summary** — bullets from the scope section, written as user-visible outcomes.
- **Test Plan** — discrete checkable steps from the `Verification` section. Include the exact commands where applicable.

Draft the PR title following the title rules in the template. The title describes this slice specifically.

Save the description (without a score table — that is added in Step 6b) to:

```
tmp/screenshots/pr/{MILESTONE}/{SLICE}/description.md
```

Create the directory if it does not exist. Do not push or create anything yet.

---

## Step 6b — Run chef:critic

Invoke `/chef:critic`. The skill runs `check-rubycritic.sh` inside Docker, handles the IMPROVED/FAIL logic, and prepends the score table to the description file saved in Step 6.

Do not proceed to Step 7 until `chef:critic` completes.

---

## Step 7 — Present draft and wait for approval

Show the full draft to the user:

```
Here is the PR draft for {MILESTONE}/{SLICE}:

Title: {title}

{body}

Approve this PR, or suggest changes.
```

Wait for an explicit response. Do not proceed to Step 8 until the user approves.

If the user requests changes, update the title or body accordingly and show the revised draft again. Repeat until the user explicitly approves. Every revision must be shown in full before asking again — never apply a change silently.

---

## Step 8 — Push and create the PR

Push the branch:

```bash
git push -u origin {branch}
```

Create the PR using the GitHub MCP tool (`mcp__github__create_pull_request`) if available. Fall back to the `gh` CLI only if the MCP is unavailable or returns an error:

```bash
gh pr create --title "{title}" --body "$(cat <<'EOF'
{approved description}
EOF
)"
```

Record the PR number and URL from the response.

If the slice had UI changes (Step 5), open the screenshots folder so the user can drag images into the PR:

```bash
uname -s
```

- `Darwin` → `open tmp/screenshots/pr/{MILESTONE}/{SLICE}/`
- `Linux` → `xdg-open tmp/screenshots/pr/{MILESTONE}/{SLICE}/`

Do not proceed to Step 9 until the PR is created successfully.

---

## Step 9 — Advance CHECKPOINT

Read `sous-chef/milestones/{MILESTONE}.md` and check for any slice that is not `STATUS: DONE`.

**If pending slices remain** (milestone is still IN_PROGRESS):

Reset CHECKPOINT to the milestone-only format — no SLICE, no STATUS:

```
MILESTONE: {MILESTONE}
```

Commit:

```bash
git add sous-chef/CHECKPOINT
git commit -m "chore({MILESTONE}/{SLICE}): slice delivered, advance to next slice"
```

**If all slices are DONE** (milestone is complete):

Update CHECKPOINT to mark the milestone complete — do not delete it:

```
MILESTONE: {MILESTONE}
STATUS: COMPLETE
```

Commit:

```bash
git add sous-chef/CHECKPOINT
git commit -m "chore({MILESTONE}): all slices delivered, milestone complete"
```

---

## Step 10 — Report

```
Delivered — {MILESTONE}/{SLICE}

  Branch:  {branch}
  PR:      {PR URL}

<if pending slices remain:>
  Milestone {MILESTONE}: {N} of {total} slices done.
  CHECKPOINT reset. Next step: /chef:refine to plan the next slice.

<if milestone complete:>
  Milestone {MILESTONE} complete — all {total} slices delivered.
  CHECKPOINT marked complete. Next step: merge the PR, then /chef:milestone to start the next milestone.
```
