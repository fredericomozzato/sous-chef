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
mise-en-place → interview → milestone → refine → build → qa → fix → deliver
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
  PRD.md                        ← feature specs (written by /chef:interview)
  ARCHITECTURE.md               ← stack decisions and non-obvious conventions
  CHECKPOINT                    ← active milestone + slice + status (updated by each skill)
  milestones/
    001-oauth.md                ← milestone with inline slices (written by /chef:milestone)
    002-articles.md
  issues/
    001-oauth/
      001.md                    ← expanded slice plan (written by /chef:refine)
      002.md
    002-articles/
      001.md
  reviews/
    001-oauth/
      001/
        revision-1.md           ← QA findings (written by /chef:qa)
    002-articles/
      001/
        revision-1.md
```

**Milestone file anatomy:**

Each milestone document contains the scope, constraints, and an ordered list of slices. Slices are high-level and intentional — no implementation details. `chef:refine` expands each slice into a full implementation plan written to `issues/`.

**File layout reference:** `skills/shared/STRUCTURE.md` is the single source of truth for all path conventions, ID/slug rules, file templates, and the slice status lifecycle. All skills read it before touching the filesystem.

## Skills

### `/chef:mise-en-place` ✅

Bootstraps the plugin and initializes the project. Does two things in one command:
1. Merges the `SessionStart` hook into `~/.claude/settings.json` (auto-loads session context)
2. Runs `mise-en-place.sh` to create the `sous-chef/` structure with template files

Safe to run multiple times — existing config and files are never overwritten.

---

### `/chef:interview` ✅

Gathers feature requirements through interactive Q&A using `AskUserQuestion` throughout. Covers product requirements, stack decisions, the standardized validation layer, and visual design (skipped for API-only projects). Asks questions until requirements are clear (~95% confidence), presents concrete alternatives with a recommended default for undecided choices, then writes:
- `sous-chef/PRD.md` — users, features (each with `STATUS: PLANNED`), UI/UX flows, design brief (palette, typography, layout, component library), and data model
- `sous-chef/ARCHITECTURE.md` — full stack table, conventions, and decision rationale

**Validation layer** — disclosed to the user at interview time and documented in both artifacts. The chef default is:

| Tool | Purpose |
|------|---------|
| RSpec + SimpleCov + Mutant | Testing and coverage |
| RuboCop + rubocop-rails + rubocop-rspec | Style and lint |
| RubyCritic | Code quality score tracking |
| Brakeman | Security vulnerability scanning |
| bundler-audit | CVE scanning on `Gemfile.lock` |
| database_consistency | DB constraint / model validation alignment |
| strong_migrations | Unsafe migration detection at boot |

The user can remove tools or replace the stack — deviations are documented in `ARCHITECTURE.md` and flagged in the completion message.

---

### `/chef:milestone` ✅

Plans the next milestone. A milestone is a scoped unit of work — it can be the full MVP, a single feature, or any bounded piece of the product. There is no fixed relationship to PRD features; scope is defined at runtime.

**What it does:**
1. Guards: requires `PRD.md` + `ARCHITECTURE.md`; blocks if a milestone is already IN_PROGRESS
2. Reads PRD and ARCHITECTURE silently for context
3. Asks the user what this milestone covers; follows up only if the scope is too vague to propose slices
4. Proposes a vertical slice breakdown (tracer-bullet), iterates until approved
5. Writes `sous-chef/milestones/NNN-slug.md` with the approved slices (all STATUS: PENDING)
6. Optionally activates: writes `CHECKPOINT` first, then sets milestone STATUS → IN_PROGRESS

**Key design decisions:**
- Milestones replace the old single `roadmap.md` — each is its own file, enabling independent scope and status tracking
- Slices inside the milestone are **intention only** — no method names, no file paths, no gem config. `chef:refine` handles the how
- `CHECKPOINT` is the single source of truth for active work. On milestone activation it holds just `MILESTONE: NNN-slug`; after the first `chef:refine` run it carries all three lines — `MILESTONE`, `SLICE`, and `STATUS` — so every downstream skill knows exactly what is being worked on without scanning any other file
- At most one milestone is IN_PROGRESS at a time. The milestone is DONE when all its slices are DONE

---

### `/chef:refine` ✅

Expands the next `PENDING` slice into a full implementation plan. Reads `CHECKPOINT` to find the active milestone, locates the first PENDING slice, surveys the relevant codebase, drafts a detailed plan (files to touch, schema changes, test cases by name), presents for approval, then writes it to `sous-chef/issues/NNN-slug/NNN.md` and overwrites `CHECKPOINT` with the full three-line format (`MILESTONE`, `SLICE`, `STATUS: IN_PROGRESS`).

If no milestone is active (no CHECKPOINT or current milestone is DONE), offers to activate a PENDING milestone first.

---

### `/chef:build` ✅

Implements the `IN_PROGRESS` slice. Guards on `CHECKPOINT` — `STATUS` must be `IN_PROGRESS`, otherwise stops and routes to the correct command. Opens the issue plan at `sous-chef/issues/{milestone-slug}/{slice-NNN}.md` as the sole contract — no PRD, ARCHITECTURE, or milestone file is consulted during implementation. Validates the plan against current code before touching any file: any referenced class, method, or file that does not exist or has drifted is reported as a blocker, and build stops until the plan is corrected.

Checks out the feature branch from the issue frontmatter (`branch:` field), then follows each numbered plan step with a strict TDD cycle: write failing RSpec examples → `rspec` (red) → implement → `rspec` (green) → commit. Each step gets its own commit: `feat({milestone-slug}/{slice-NNN}): description`. After all steps pass, runs `pre-commit-checks.sh` as a hard gate — every check must be green, no exceptions.

Updates status in three places — issue frontmatter, milestone slice, and `CHECKPOINT` — from `IN_PROGRESS` to `IN_REVIEW`, commits the three files together, then hands off to `/chef:qa`.

---

### `/chef:qa` 🔲

Reviews the `IN_REVIEW` slice in three phases:
1. Build gate + completeness audit — runs `pre-commit-checks.sh` and verifies every scope bullet is implemented and tested
2. Execution trace — follows the code from entrypoint to exitpoint to understand what the feature actually does before judging it
3. Implementation review — bugs, architecture deviations, anti-patterns

If findings exist, writes `sous-chef/reviews/NNN-slug/NNN/revision-N.md` and hands off to `chef:fix`. If clean, marks the slice `DONE`. Findings describe problems only — no fix instructions.

---

### `/chef:browser-testing` 🔲

Optional browser smoke test for slices that touch views. Opens the app in a real browser via Playwright, exercises the slice UI flows, and captures screenshots. Intended to complement RSpec system specs, not replace them. Run it after `/chef:qa` passes when you want visual confirmation before opening a PR.

---

### `/chef:fix` ✅

Resolves all `OPEN` findings in the active revision file, highest severity first. For each finding: implements the fix (writing a failing RSpec example first for behavioral bugs), iterates on `pre-commit-checks.sh` until green, marks the finding `FIXED` in the revision file, then commits immediately — one commit per finding for full auditable history. Escalates to the user only if genuinely stuck after exhausting approaches. When all findings are resolved, hands back to `/chef:qa`.

---

### `/chef:deliver` ✅

Ships the completed slice as a PR. A milestone delivers through multiple `chef:deliver` runs — one per slice.

**Guards:** requires `CHECKPOINT` with `STATUS: DONE`, no open QA revisions (`status: IN_PROGRESS`) for the active slice, and `pre-commit-checks.sh` passing. On any failure it stops and reports — it never attempts to fix.

**UI slices:** if the slice touches views, prompts for (or decides) which screen sizes to capture, then delegates screenshot capture to a Haiku subagent via Playwright. Screenshots are saved to `tmp/pr/{milestone}/{slice}/` and included in the PR description as `<!-- IMAGE: -->` placeholders. The folder is opened automatically after capture.

**PR:** drafts a title (slice-scoped, bracketed type prefix) and a two-section body — `Summary` (user-visible outcomes) and `Test Plan` (discrete verification steps from the issue file), plus a `Screenshots` section when applicable. Shows the full draft to the user and iterates until explicit approval. Only then pushes the branch and creates the PR via GitHub MCP (fallback: `gh` CLI).

**CHECKPOINT:** after the PR is created, checks whether the milestone has remaining slices. If yes, resets `CHECKPOINT` to the milestone-only line so `/chef:refine` can pick up the next slice. If all slices are done, deletes `CHECKPOINT` to unblock `/chef:milestone`.

---

## Progress

| Skill | Status |
|---|---|
| `chef:mise-en-place` | ✅ Done |
| `chef:interview` | ✅ Done |
| `chef:milestone` | ✅ Done |
| `chef:refine` | ✅ Done |
| `chef:build` | ✅ Done |
| `chef:qa` | ✅ Done |
| `chef:fix` | ✅ Done |
| `chef:deliver` | ✅ Done |
| `chef:browser-testing` | 🔲 Planned |
