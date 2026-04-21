# Screenshot Flow — UI Slice Delivery

Follow this flow when `chef:deliver` detects UI changes in the active slice. Complete all steps here before returning to the deliver skill to draft the PR description.

---

## Step 1 — Determine screen types

Read the slice scope bullets to understand what UI is being delivered. Based on that, decide which screen widths and states are relevant.

If the scope bullets don't make it obvious (e.g. a layout used across breakpoints, a component with no clear primary viewport), ask the user:

```
This slice touches views. Which screen sizes should I capture?
Suggestion based on the slice: {your suggestion}

Confirm or specify different sizes.
```

Use the user's answer (or your own judgment if the scope is unambiguous) to define the capture plan before opening the browser.

---

## Step 2 — Define states to capture

For each screen size, identify the relevant states from the slice scope. At minimum cover:

- **Default / loaded state** — the feature as it appears on first load
- **Filled / active state** — the feature after user interaction (form filled, item selected, etc.)
- **Error / edge state** — validation errors, empty results, boundary conditions
- **Any state explicitly mentioned in the scope bullets**

Skip states that don't apply to the slice (e.g. no error state for a read-only view).

---

## Step 3 — Delegate to a Haiku subagent

Spawn a subagent using the cheapest available model (Haiku on Claude, gemini-flash on Gemini) to perform the captures. Pass it:

- The app URL and any required auth/setup steps
- The list of states and screen sizes from Steps 1–2
- The output folder: `tmp/pr/{MILESTONE}/{SLICE}/`
- The naming convention from Step 4

This keeps screenshot I/O out of the main context window.

---

## Step 4 — Naming convention

```
{NNN}_{state_description}_{width}.png
```

- `NNN` — three-digit sequence number starting at `001`
- `state_description` — lowercase with underscores, describes what is shown
- `width` — viewport label (e.g. `desktop`, `tablet`, `mobile`, or the actual pixel width like `1280px`)

Examples:
```
001_empty_state_desktop.png
002_form_filled_desktop.png
003_validation_error_desktop.png
004_empty_state_mobile.png
```

If only one screen size is captured, the width suffix can be omitted.

---

## Step 5 — Save location

All screenshots go to:

```
tmp/pr/{MILESTONE}/{SLICE}/
```

Create the directory if it does not exist. Do not commit this folder — `tmp/` should be in `.gitignore`.

---

## Step 6 — Open the folder

After all screenshots are saved, open the folder in the system file explorer so the user can review the captures immediately:

```bash
# macOS
open tmp/pr/{MILESTONE}/{SLICE}/

# Linux
xdg-open tmp/pr/{MILESTONE}/{SLICE}/
```

Detect the OS with `uname -s`: `Darwin` → macOS, `Linux` → Linux.

---

## Step 7 — Return to deliver

Return to `chef:deliver` Step 6 (Draft the PR description). The screenshots are now available at `tmp/pr/{MILESTONE}/{SLICE}/`.

When drafting the PR body, add a `## Screenshots` section after `## Test Plan`. For each screenshot, add a short caption followed by the image placeholder:

```markdown
## Screenshots

{Caption describing what is shown}

<!-- IMAGE: 001_empty_state_desktop.png -->

{Caption describing what is shown}

<!-- IMAGE: 002_form_filled_desktop.png -->
```

Use `<!-- IMAGE: filename.png -->` — filename only, no folder path.
