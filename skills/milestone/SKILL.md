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

## Step 1 — Guard

Check that both `sous-chef/PRD.md` and `sous-chef/ARCHITECTURE.md` exist.

If either is missing, stop:
```
Cannot create a milestone — sous-chef/PRD.md and sous-chef/ARCHITECTURE.md are required.
Run /chef:interview first to document the app requirements and stack.
```

Check for an existing active milestone: read `sous-chef/CHECKPOINT`. If the file exists, an active milestone is already in progress — stop:
```
There is already an active milestone: {MILESTONE value from CHECKPOINT}
Finish the current milestone before starting a new one.
```
If CHECKPOINT does not exist, no milestone is active — proceed.

## Step 2 — Read context

Read `sous-chef/PRD.md` and `sous-chef/ARCHITECTURE.md` silently. Do not summarize them to the user.

## Step 3 — Determine milestone ID

List files in `sous-chef/milestones/` (create the folder if it does not exist). Find the highest existing NNN prefix and increment by one, zero-padded to three digits. If no milestones exist, start at `001`.

## Step 4 — Scope interview

Ask one opening question:

> "What are we building in this milestone? It can be the full MVP, a single feature, or any scoped piece of the product you want to ship next."

Follow up only if the opening answer is too vague to propose slices — for example, if no feature boundary is clear, or if a known constraint from ARCHITECTURE.md creates ambiguity the answer doesn't resolve:
- What is explicitly out of scope for this milestone?
- Any dependencies on other work, technical risks, or decisions not yet in ARCHITECTURE?

Stop asking when you can propose a concrete slice list.

## Step 5 — Propose slices

Using the PRD, ARCHITECTURE, and the scope from Step 4, propose a slice breakdown following the tracer-bullet principle:

- Each slice delivers a working vertical increment — something the user can see or interact with
- Slices are ordered so each one builds on the previous
- No slice assembles a single horizontal layer in isolation
- The first slice should be the thinnest possible walking skeleton: runnable, visible, end-to-end

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

Ask: *"Does this breakdown make sense? Anything to split, merge, reorder, or add?"*

Iterate until the user explicitly approves. Do not write any file until confirmed.

## Step 6 — Write the milestone file

Use the milestone file template from `skills/shared/STRUCTURE.md`. Write to `sous-chef/milestones/{NNN}-{slug}.md`.

Slice numbers are per-milestone, always starting at `001`, zero-padded to three digits as defined in STRUCTURE.md.

**Scope bullet guide:** layer-aware, not implementation-specific.
- "Article model with title, body, and published_at" ✓ — "add `t.string :title` to migration" ✗
- "Devise installation and configuration" ✓ — "add `gem 'devise'` to Gemfile" ✗

## Step 7 — Activate?

Ask: *"Ready to start building? I can activate this milestone now."*

**If yes:**
1. Write `sous-chef/CHECKPOINT` first (creating it if it does not exist):
   ```
   MILESTONE: {NNN}-{slug}
   ```
   No SLICE or STATUS line yet — those are written by `chef:refine` when a slice is activated.
2. Then update the milestone frontmatter: `status: PENDING` → `status: IN_PROGRESS`

Writing CHECKPOINT first ensures the system is never left with an IN_PROGRESS milestone that has no CHECKPOINT entry.

**If no:** leave status as PENDING. When `chef:refine` runs later with no active CHECKPOINT, it will offer to activate a pending milestone.

## Step 8 — Report

```
Milestone {NNN} created: {title}

  sous-chef/milestones/{NNN}-{slug}.md

  Slices:
    001 — {name}
    002 — {name}
    ...

Status: {PENDING | IN_PROGRESS}

Next step: /chef:refine to plan and expand the first slice.
```
