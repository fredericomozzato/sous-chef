# Sous Chef
A Claude Code plugin to streamline development focused on Ruby on Rails applications. The name was borrowed from the book Vibe Coding by Gene Kim and Steve Yegge where they compare the use of coding agents as having a sous chef helping us (the head chef) to achieve our vision.


## Purpose
I've been trying to use other frameworks like [GSD]() and [Openspec](). Both are **really** good, but I feel they're extremely verbose and kill my usage in almost no time (I use the pro plan, so not many tokens to spare per session).

Thinking about these limitations I decided to aggregate the tools I built over time into a single plugin to help me develop apps in a predictable way while not burning all my tokens in minutes.


## Why focus on Ruby on Rails?
This is the main tech stack that I use. Yes, coding agents can help us write code in any language and stacks, but this one is a lightweight framework to help with a more specific sstack, allowing me to create focused tools and workflows.

As Rails users we are kind of accostumed with the *omakase* approach... so I created this plugin to be just like that: a set of conventions that I use in my projects. Sous Chef will help quickly prototyping and testing Rails applications with a predictable infracstructure.

## Installation

Run these two commands inside Claude Code:

```
/plugin marketplace add fredericomozzato/sous-chef
/plugin install chef@sous-chef
```

Then bootstrap the plugin configuration:

```
/chef:setup
```

This adds the required hooks to `~/.claude/settings.json`. Restart Claude Code or open `/hooks` once to activate.

---

# Usage
The plugin is named Sous Chef, but I simplified the usage name to `chef` (less typing is always good).


# Features

## `/chef:create-issue`

Creates a GitHub issue following a structured workflow: gathers requirements, formats the title as `[TYPE] Brief description` (e.g. `[FEAT] Add calculator page`), determines the assignee interactively, writes a Markdown body with a problem description, definition-of-done checklist, and TDD execution instructions, then presents the draft for your approval before creating it.

**Usage:** `/chef:create-issue` — describe the issue when prompted, or include a description inline.

---

## `/chef:solve-issue <issue-number>`

Fetches a GitHub issue and implements a full solution end-to-end: creates a properly-named branch off `main`, implements the feature or fix with 100% RSpec test coverage using TDD (red → green → refactor), runs pre-commit checks after each cycle, requests your review before opening a PR, then delegates to `/chef:create-pull-request` to finalize.

**Usage:** `/chef:solve-issue 42` or `/chef:solve-issue 42 use Turbo Streams` to pass additional instructions.

---

## `/chef:create-pull-request`

Creates a pull request (or updates an existing PR description) with a full quality gate: runs `bundler-audit` (hard block on vulnerabilities), captures screenshots for UI changes, writes a description following the project template, waits for your explicit approval, then creates the PR via the GitHub MCP (fallback: `gh` CLI).

**Usage:** `/chef:create-pull-request` — invoke after your branch is ready to ship.

---

## `/chef:setup`

Bootstraps the plugin after installation. Merges the required `SessionStart` hook into `~/.claude/settings.json` so handoff context loads automatically on every new session. Safe to run multiple times — existing config is preserved.

**Usage:** `/chef:setup` — run once after installing the plugin, then restart Claude Code or open `/hooks` to activate.

---

## `/chef:handoff`

Saves a snapshot of the current session before stepping away. Dispatches a Haiku sub-agent to summarize git history, changed files, work done, work remaining, and key decisions into a handoff file at `~/.claude/progress/{project}/{branch}/session-NNN.md` (100-line cap). Running it multiple times in the same session updates the same file; a new session creates the next numbered file. On the next session start, the file is injected automatically — no manual action needed.

**Usage:** `/chef:handoff` — invoke before ending a session on any active branch.

---

## `/chef:critic`

Runs RubyCritic against the `app/` directory and compares the score against the project minimum stored in `.rubycritic_minimum_score`. PASS continues silently; IMPROVED auto-updates the minimum file (you commit it); FAIL soft-blocks and asks how to proceed. Produces the score table and optional Score Trade-off section for the PR description.

**Usage:** `/chef:critic` — called automatically as part of `/chef:create-pull-request`, or run standalone before opening a PR.

---

# New Flow

A structured workflow for planned feature development — from blank project to shipped PR.

## Overview

```
mise-en-place → interview → refine → build → qa → fix → deliver
```

## Slices, not layers

Most AI-assisted projects end up built horizontally: all migrations first, then all models, then all controllers, then all views. You spend hours on infrastructure with nothing to show for it — and by the time something is visible, the earlier layers are already drifting from the actual requirements.

Sous Chef builds **vertically**. Each unit of work is a **slice** — a thin, end-to-end piece of a feature that touches every layer of the application: database migration, model, business logic, controller, view, and tests. Each slice ships as working software. You see results immediately, and every iteration is a complete, testable feature increment.

Think of it as a tracer bullet: a narrow path cut all the way through the stack to prove the architecture works and deliver visible value, before widening it with the next slice.

**Example — a "user posts an article" feature broken into slices:**

| # | Slice | Layers touched |
|---|---|---|
| 001 | Create article (title + body, no auth) | migration → model → controller → form → test |
| 002 | Add authorship (article belongs to user) | migration → model → policy → controller → view → test |
| 003 | Publish / draft toggle | model state machine → controller action → Turbo Stream → test |
| 004 | Article index with pagination | query → controller → view component → test |

Each slice is independently deployable and reviewable. No slice leaves the stack half-assembled.

**Slice lifecycle:**
```
PENDING → IN_PROGRESS → IN_REVIEW → DONE
(refine)   (build)        (qa)     (qa clean)
```

## Project Structure

Created by `/chef:mise-en-place` inside the Rails app:

```
sous-chef/
  PRD.md              ← feature specs (written by /chef:interview)
  ARCHITECTURE.md     ← stack decisions and non-obvious conventions
  roadmap.md          ← slices + statuses
  issues/
    001-slug.md       ← per-slice plan (pending → in_progress → in_review → done)
  reviews/
    001-slug/
      revision-1.md   ← QA findings (in_progress → done)
```

## Skills

### `/chef:mise-en-place` ✅

Bootstraps the plugin and initializes the project. Does two things in one command:
1. Merges the `SessionStart` hook into `~/.claude/settings.json` (auto-loads session context)
2. Runs `mise-en-place.sh` to create the `sous-chef/` structure with template files

Safe to run multiple times — existing config and files are never overwritten.

---

### `/chef:interview` 🔲

Gathers feature requirements through a one-pass Q&A — all questions at once, all files written once. Outputs:
- `sous-chef/PRD.md` — feature specs, users, UI/UX, data model
- `sous-chef/ARCHITECTURE.md` — stack decisions and non-obvious conventions
- `sous-chef/roadmap.md` — one slice per feature, all `STATUS: PENDING`
- `sous-chef/issues/NNN-slug.md` — stub issue file per slice

---

### `/chef:refine` 🔲

Plans the next `PENDING` slice. Surveys the relevant codebase, drafts a detailed implementation plan (files to touch, schema changes, test cases by name), presents for approval, then writes the plan to the issue file and advances to `IN_PROGRESS`.

---

### `/chef:build` 🔲

Implements the `IN_PROGRESS` slice. Validates the plan against current code, switches to the feature branch, and follows a strict red → green → commit TDD cycle. Advances to `IN_REVIEW` on completion.

---

### `/chef:qa` 🔲

Reviews the `IN_REVIEW` slice in two phases:
1. Smoke test + completeness audit — all scope items implemented and tested
2. Implementation review — bugs, architecture deviations, anti-patterns

If findings exist, writes `sous-chef/reviews/NNN-slug/revision-N.md`. If clean, marks the slice `DONE`.

---

### `/chef:fix` 🔲

Resolves all `OPEN` findings in the active revision file, highest severity first. Each fix is verified with `pre-commit-checks.sh`, committed, and marked `FIXED`. When all findings are resolved, hands back to `/chef:qa`.

---

### `/chef:deliver` 🔲

Final delivery gate:
1. Verifies the current slice is `DONE` in the roadmap
2. Runs `pre-commit-checks.sh` as a final gate
3. Delegates to `/chef:create-pull-request` to open the PR

---

## Progress

| Skill | Status |
|---|---|
| `chef:mise-en-place` | ✅ Done |
| `chef:interview` | 🔲 Planned |
| `chef:refine` | 🔲 Planned |
| `chef:build` | 🔲 Planned |
| `chef:qa` | 🔲 Planned |
| `chef:fix` | 🔲 Planned |
| `chef:deliver` | 🔲 Planned |
