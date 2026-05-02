---
name: chef:browser-testing
description: Use when the user runs /chef:browser-testing to smoke-test the active slice in a real browser via Playwright, capture screenshots, and report UI findings into the revision workflow.
---

# Browser Testing — Slice Smoke Test

Test the active slice in a real browser using Playwright. Covers user-visible flows end-to-end: navigation, interactions, error states. Findings are written into the existing QA revision file if one is open, or into a new revision if not. Screenshots are always captured and saved locally.

**Announce at start:** "Using the browser-testing skill to smoke-test the active slice."

**File layout:** read `skills/shared/STRUCTURE.md` before touching any files. Read `skills/shared/revision-template.md` before writing or appending to any revision file.

---

## Step 1 — Guard

Read `sous-chef/CHECKPOINT`.

If CHECKPOINT is missing, stop:
```
No active milestone. Run /chef:milestone to start one.
```

Parse the fields. If `MILESTONE` or `SLICE` are absent, stop:
```
No slice is active. Run /chef:refine to plan a slice first.
```

`STATUS` does not block this skill — browser testing is valid at `IN_PROGRESS`, `IN_REVIEW`, or `DONE`.

Record `MILESTONE` and `SLICE` for use in subsequent steps.

---

## Step 2 — Load context (silent)

Read `sous-chef/issues/{MILESTONE}/{SLICE}.md`. Extract:

- Scope bullets — what the slice delivers
- Any views, routes, forms, Turbo Streams, or browser-visible output mentioned
- Entry points (routes, controller actions)

Read `sous-chef/ARCHITECTURE.md` to confirm the app URL and port (default: `http://localhost:3000`).

---

## Step 3 — Server check

Verify the app is responding:

```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000
```

If the status code is not `200` or `302`, stop:

```
The app is not responding at http://localhost:3000.

Start the Rails server first:
  bin/dev   (or rails server)

Then re-run /chef:browser-testing.
```

If ARCHITECTURE.md specifies a different port, use that URL in the curl check and in all subsequent steps.

---

## Step 4 — Derive a test plan

From the scope bullets, produce a test matrix before opening the browser. For each user-visible flow, define:

- **URL** to navigate to
- **Actions** to perform (fill form, click button, follow link, etc.)
- **States to capture:**
  - Default / loaded state — as it appears on first load
  - Filled / interacted state — after user action
  - Error / edge state — validation failures, empty results, boundary conditions
  - Any state explicitly named in scope bullets

Skip states that clearly don't apply to the slice (e.g. no error state for a read-only display).

Report the plan briefly before proceeding:

```
Test plan — {N} flows, {M} scenarios:
  Flow 1: {description} — {N} states
  Flow 2: {description} — {N} states
  ...
```

No approval needed — this is for transparency only.

---

## Step 5 — Execute browser tests via Playwright

Prepare the screenshots output directory:

```
tmp/screenshots/qa/{MILESTONE}/{SLICE}/
```

Create it if it does not exist. Do not commit this folder — `tmp/` is gitignored.

For each scenario in the test plan, in order:

1. Navigate to the URL using Playwright
2. Take a screenshot of the initial state
3. Perform the defined interaction(s)
4. Take a screenshot of the result state
5. Note any of the following if observed:
   - Console errors or JavaScript exceptions
   - HTTP errors (4xx, 5xx in network requests)
   - Missing or broken UI elements (wrong layout, overlapping content, missing text)
   - Behaviour that contradicts the scope bullets

**Screenshot naming convention:**

```
{NNN}_{state_description}_{width}.png
```

- `NNN` — three-digit sequence, starting at `001`, incrementing across all screenshots in this run
- `state_description` — lowercase with underscores (e.g. `article_form_empty`, `validation_error`, `article_created`)
- `width` — viewport label (`desktop`, `tablet`, `mobile`, or pixel value like `375px`). Omit if only one viewport is tested.

**Examples:**
```
001_article_index_empty_desktop.png
002_new_article_form_desktop.png
003_validation_error_desktop.png
004_article_index_empty_mobile.png
```

Save every screenshot to `tmp/screenshots/qa/{MILESTONE}/{SLICE}/`.

---

## Step 6 — Open the screenshots folder

After all screenshots are saved, open the folder so the user can review captures immediately:

```bash
uname -s
```

- `Darwin` → `open tmp/screenshots/qa/{MILESTONE}/{SLICE}/`
- `Linux` → `xdg-open tmp/screenshots/qa/{MILESTONE}/{SLICE}/`

---

## Step 7 — Triage findings

Review every observation noted during Step 5. Classify each as a finding only if it represents a real defect or deviation:

**Finding prefixes:** `U` (e.g. `U1`, `U2`)

**Severities:**
- `BLOCKER` — app crashes, unhandled exceptions, 500 errors, page fails to load
- `HIGH` — feature does not behave as the scope bullet describes
- `MED` — UI inconsistency, broken layout, wrong copy, missing element
- `LOW` — cosmetic issue, minor visual drift

**Finding format** (flat inline, matching the existing QA format):

```
**U1** · HIGH · OPEN · `app/views/articles/new.html.erb`
Submitting the form with a blank title renders a 500 instead of the validation error message. Observed at http://localhost:3000/articles/new — console shows: ActionView::Template::Error.

**U2** · MED · OPEN · `app/views/articles/index.html.erb`
Article list renders with no vertical spacing between entries on mobile viewport (375px). Title text overlaps the author line.
```

If no findings exist, skip Steps 8 and 9 — proceed directly to Step 10 (clean pass).

---

## Step 8 — Find the active revision

List all files matching `sous-chef/reviews/{MILESTONE}/{SLICE}/revision-*.md`.

Read the frontmatter of each. Look for one with `status: IN_PROGRESS`.

**If an open revision is found:** proceed to Step 9a.

**If no open revision is found:** proceed to Step 9b.

---

## Step 9a — Append to existing revision

Append a new section to the open revision file:

```markdown
## Phase 3 — Browser Testing

**U1** · HIGH · OPEN · `path/to/file`
Description of the defect, including URL and any console output.

**U2** · MED · OPEN · `path/to/file`
Description of the defect.
```

Do not change the frontmatter `status` — it remains `IN_PROGRESS`. Do not renumber existing finding IDs.

---

## Step 9b — Create a new revision file

**Determine revision number:** count existing `revision-*.md` files in `sous-chef/reviews/{MILESTONE}/{SLICE}/`. Next revision = count + 1. Create the directory if it does not exist.

Read `skills/shared/revision-template.md` for the file template, finding format, severities, and status values. Follow it exactly when writing the file.

Write `sous-chef/reviews/{MILESTONE}/{SLICE}/revision-N.md` using the frontmatter from the template. Omit Phase 1 and Phase 2 sections — include only `## Phase 3 — Browser Testing` with the `U`-prefixed findings.

Do not update CHECKPOINT, the issue frontmatter, or the milestone file — this skill does not change slice status.

---

## Step 10 — Report

**If findings were written:**

```
Browser testing complete — {MILESTONE}/{SLICE}

Flows tested:    {N}
Screenshots:     {M} saved to tmp/screenshots/qa/{MILESTONE}/{SLICE}/

Open findings ({N} total):
  U1 · {SEVERITY} — {one-line summary}
  U2 · {SEVERITY} — {one-line summary}

<if appended to existing revision:>
Written to: sous-chef/reviews/{MILESTONE}/{SLICE}/revision-N.md (appended)

<if new revision created:>
Written to: sous-chef/reviews/{MILESTONE}/{SLICE}/revision-N.md (new)

Next step: /chef:fix to resolve findings, then /chef:qa.
Tip: run /clear to free up context first.
```

**If no findings:**

```
Browser testing complete — {MILESTONE}/{SLICE}

Flows tested:    {N}
Screenshots:     {M} saved to tmp/screenshots/qa/{MILESTONE}/{SLICE}/

All scenarios passed — no browser findings.
```
