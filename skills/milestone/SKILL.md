---
name: chef:milestone
description: Plan a milestone — interview the user about scope, propose slices, write the milestone document, and optionally activate it.
---

# Milestone

Plan what to build next. Reads PRD and ARCHITECTURE for context, interviews the user to establish the scope of this milestone, proposes a slice breakdown, and writes the milestone document. Optionally activates the milestone for immediate work.

**File layout:** read `skills/shared/STRUCTURE.md` for path conventions, ID format, slug rules, and the milestone file template before writing any files.

## Core rules

- **Read PRD and ARCHITECTURE before asking anything.** The user should not have to re-explain their own app.
- **Use `AskUserQuestion` for every question.** Never prompt inline.
- **Slices are intention, not implementation.** No method names, no gem config, no file paths — just what gets built and what the user can do afterward. `chef:refine` handles the how.
- **Each slice must be vertical.** It touches every layer it needs end-to-end. No "migrations only" or "views only" slices.
- **Propose, don't just ask.** Present a concrete slice breakdown and let the user refine it.

---

## Step 1 — Sync main

Ensure we are on `main` with the latest changes before any planning:

```bash
git checkout main && git pull origin main
```

## Step 2 — Locate the sous-chef directory

Before any file access, determine where the project's sous-chef directory lives. Check in this order:

1. `sous-chef/` — exists → use `sous-chef` as the base path (referred to as `$SC_DIR` for the rest of this skill)
2. `.sous-chef/` — exists → use `.sous-chef` as `$SC_DIR`
3. Neither exists → stop:
   ```
   Cannot find a sous-chef project directory. Expected sous-chef/ or .sous-chef/ in the current directory.
   Run /chef:interview first to document the app requirements and stack.
   ```

## Step 3 — Guard

Check that both `$SC_DIR/PRD.md` and `$SC_DIR/ARCHITECTURE.md` exist.

If either is missing, stop:
```
Cannot create a milestone — $SC_DIR/PRD.md and $SC_DIR/ARCHITECTURE.md are required.
Run /chef:interview first to document the app requirements and stack.
```

Check for an existing active milestone: read `$SC_DIR/CHECKPOINT`. If the file exists, parse its `STATUS` field:

- `STATUS: COMPLETE` — the previous milestone's PR is open but not yet merged. Proceed, but note to the user:
  ```
  Note: {MILESTONE} is marked complete but its PR may not be merged yet. Continuing to plan the next milestone.
  ```
- Any other status, or no STATUS field — an active milestone is in progress. Stop:
  ```
  There is already an active milestone: {MILESTONE value from CHECKPOINT}
  Finish the current milestone before starting a new one.
  ```

If CHECKPOINT does not exist, no milestone has ever been activated — proceed.

## Step 4 — Read context

Read `$SC_DIR/PRD.md` and `$SC_DIR/ARCHITECTURE.md` silently. Do not summarize them to the user.

## Step 5 — Determine milestone ID

List files in `$SC_DIR/milestones/` (create the folder if it does not exist). Find the highest existing NNN prefix and increment by one, zero-padded to three digits. If no milestones exist, start at `001`.

## Step 6 — Scope interview

Ask one opening question:

> "What are we building in this milestone? It can be the full MVP, a single feature, or any scoped piece of the product you want to ship next."

Follow up only if the opening answer is too vague to propose slices — for example, if no feature boundary is clear, or if a known constraint from ARCHITECTURE.md creates ambiguity the answer doesn't resolve:
- What is explicitly out of scope for this milestone?
- Any dependencies on other work, technical risks, or decisions not yet in ARCHITECTURE?

Stop asking when you can propose a concrete slice list.

## Step 7 — Check for Rails app

Before proposing slices, check whether a `Gemfile` exists in the current directory:

```bash
test -f Gemfile && echo "exists" || echo "missing"
```

Keep this result in mind for the next step. Do not report it to the user.

## Step 8 — Propose slices

Using the PRD, ARCHITECTURE, and the scope from Step 6, propose a slice breakdown following the tracer-bullet principle:

- Each slice delivers a working vertical increment — something the user can see or interact with
- Slices are ordered so each one builds on the previous
- No slice assembles a single horizontal layer in isolation
- The first slice should be the thinnest possible walking skeleton: runnable, visible, end-to-end

**If the `Gemfile` was missing in Step 7**, always prepend a bootstrap slice as `001` regardless of the milestone scope:

```
  001 — Bootstrap the application
        Delivers: Rails app and Docker environment ready for development
        Note: run /chef:bootstrap to complete this slice — do not scaffold manually
```

Then number the feature slices starting at `002`.

**If the `Gemfile` exists**, propose feature slices starting at `001` as normal.

Present as a numbered list with a one-line "delivers" for each:

```
Proposed slices:

  001 — Devise setup and basic auth
        Delivers: user can register, log in, and log out with email/password

  002 — Google OAuth provider
        Delivers: user can sign in with Google

  003 — Remember me and session persistence
        Delivers: user stays logged in across browser restarts
```

**Output the slice list as plain text in your response first.** Then call `AskUserQuestion` to ask for feedback — never put the slice list inside the `AskUserQuestion` call.

Ask: *"Does this breakdown make sense? Anything to split, merge, reorder, or add?"*

Iterate until the user explicitly approves. Do not write any file until confirmed.

## Step 9 — Write the milestone file

Use the milestone file template from `skills/shared/STRUCTURE.md`. Write to `$SC_DIR/milestones/{NNN}-{slug}.md`.

Slice numbers are per-milestone, always starting at `001`, zero-padded to three digits as defined in STRUCTURE.md.

**Scope bullet guide:** layer-aware, not implementation-specific.
- "Article model with title, body, and published_at" ✓ — "add `t.string :title` to migration" ✗
- "Devise installation and configuration" ✓ — "add `gem 'devise'` to Gemfile" ✗

## Step 10 — Activate?

Ask: *"Ready to start building? I can activate this milestone now."*

**If yes:**
1. Write `$SC_DIR/CHECKPOINT` first (creating it if it does not exist):
   ```
   MILESTONE: {NNN}-{slug}
   ```
   No SLICE or STATUS line yet — those are written by `chef:refine` when a slice is activated.
2. Then update the milestone frontmatter: `status: PENDING` → `status: IN_PROGRESS`

Writing CHECKPOINT first ensures the system is never left with an IN_PROGRESS milestone that has no CHECKPOINT entry.

**If no:** leave status as PENDING. When `chef:refine` runs later with no active CHECKPOINT, it will offer to activate a pending milestone.

## Step 11 — Report

```
Milestone {NNN} created: {title}

  $SC_DIR/milestones/{NNN}-{slug}.md

  Slices:
    001 — {name}
    002 — {name}
    ...

Status: {PENDING | IN_PROGRESS}

Next step: /chef:refine to plan and expand the first slice.
Tip: run /clear to free up context first.
```
