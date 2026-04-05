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

# Architecture

Sous Chef is organized into three layers. Each layer has a distinct responsibility and a defined interface to the next.

## Planning Layer

The planning layer handles everything before a line of code is written. Its job is to produce a shared, approved understanding of what needs to be built and in what order.

### Agents

**Interview Agent**
Conducts a back-and-forth conversation with the user to clarify intent. Uses `AskUserQuestion` to gather information until it reaches ~99% confidence about what needs to be built. During the interview, the agent assesses scope and will suggest splitting large requests into milestones or a full roadmap if appropriate. The conversation ends when both parties agree on what is in and out of scope.

Once scope is agreed, the agent drafts a `prd.md` following the project PRD template. The PRD includes a scope/horizon indicator (`task | milestone | roadmap`) so the decomposition agent knows what level of detail to apply. The user must approve the PRD before the process continues.

**Decomposition Agent**
Reads the approved `prd.md` and breaks the work into discrete, ordered tasks. Each task includes a dependency reference where applicable — e.g. `task-003 (blocked by task-001)` — so that parallelizable work is explicitly identified. The agent adapts its output to the scope: a single task produces a flat checklist; a milestone produces a sequenced task list; a roadmap produces grouped milestones with tasks under each.

The agent proposes the breakdown as a `roadmap.md` and presents it to the user for feedback. The loop continues until the user approves.

### Storage

Plans are stored inside the repository under `./sous-chef/plans/`. Each plan gets its own folder named with an auto-incremented ID and a brief slug:

```
./sous-chef/plans/
  0001_user-authentication/
    prd.md
    roadmap.md
  0002_billing-integration/
    prd.md
    roadmap.md
```

Plan folders are scoped to the current git branch. When a planning command is invoked, the agent checks `./sous-chef/plans/` for an existing plan on the current branch and offers to resume it.

### Commands

| Command | Purpose |
|---|---|
| `/chef:plan` | High-level entry point. Runs the interview agent, produces `prd.md` and `roadmap.md`, and optionally creates GitHub issues. |
| `/chef:plan-task <issue-number>` | Low-level entry point. Fetches a GitHub issue and re-enters the planning layer to flesh out detail for that specific task. Produces a task-scoped `prd.md` and `roadmap.md`. |

### GitHub Integration

After the roadmap is approved, the agent offers to push the plan to GitHub. Tasks become issues; milestones become GitHub milestones with issues linked to them. The `roadmap.md` is updated with GitHub issue numbers to keep the local plan and remote issues in sync.

Once issues exist on GitHub, the GitHub issue number becomes the canonical reference for the execution layer. All downstream work (`/chef:solve-issue`) operates off issue numbers, not local plan IDs.

### Recursive Planning

The planning layer is designed to be re-entered at different levels of detail. A roadmap-level plan may not have enough information to implement individual tasks directly. In that case, `/chef:plan-task` is invoked with a specific issue number to produce a more detailed plan for that task before the execution layer picks it up.

### Exiting the Planning Layer

The planning layer is exited when both documents are approved and (optionally) issues are created on GitHub. If the user wants to abandon a plan, they can exit the session and delete the plan folder manually. A fresh run of `/chef:plan` on the same branch will start from scratch.

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
