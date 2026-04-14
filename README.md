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

## Execution Layer

The execution layer picks up where planning stops. Its job is to turn an approved plan into merged, production-ready code. It owns the full cycle: branch creation, TDD implementation, quality gates, and PR opening.

### Agents

**Execution Agent**
Reads the GitHub issue and the corresponding plan documents from `./sous-chef/plans/` (if a task-scoped plan exists), then produces its own low-level implementation plan before touching any code. This plan is written to `./sous-chef/plans/<plan-id>/impl.md` so it survives context resets and handoffs.

With the implementation plan in hand, the agent enters a TDD loop:

1. Write a failing spec (red)
2. Write the minimum code to pass (green)
3. Refactor — clean up without breaking the spec
4. Commit the logical unit of work with a semantic commit message
5. Repeat until all tasks in the implementation plan are done

The agent runs autonomously and stops only when it hits a defined blocker (see below).

**Frontend work** is identified by the execution agent during implementation planning. Whenever a task requires creating or modifying views, templates, or CSS, the agent invokes the `frontend-design` skill before writing any UI code. No tagging or signal from the planning layer is required — the agent infers the need from what it is about to build.

### Blockers

The agent pauses and asks for input only when it encounters one of two conditions:

- **Ambiguous requirements** — the PRD or task leaves something genuinely unclear that would require a design decision to proceed.
- **Destructive operations** — the task implies dropping tables, deleting records, or other irreversible data changes that require explicit sign-off.

All other obstacles (failing tests, environment issues, tool errors) are investigated and resolved autonomously.

### Branch and Commit Strategy

Each issue gets one branch. The branch name is derived directly from the GitHub issue: the type prefix comes from the issue title type tag (`feat`, `fix`, `docs`, `agents`, `chore`), followed by the issue number and a slugified title — e.g., `feat/42-add-user-authentication`. The agent reads the issue and constructs the branch name without making its own type judgment.

The agent groups related TDD cycles into semantic commits — one commit per logical unit (e.g., `add User model`, `add session controller`, `add login UI`) — rather than one commit per cycle. The PR is squash-merged.

### Quality Gate

After all implementation cycles complete, the agent runs the following checks in order before opening the PR. **The PR is blocked until all checks pass.**

| Check | Tool | Scope |
|---|---|---|
| Security audit | `brakeman` | Full app |
| Code quality | `rubycritic` (`/chef:critic`) | Full app, scored against project minimum |

If any check fails, the agent reports the failures and stops. It does not auto-fix. You decide how to proceed: patch and re-run, or override.

Mutation testing is intentionally excluded from this gate — it is owned by the QA layer and runs after the PR is opened.

### Environment Context

The agent reads environment conventions (how to start Docker, run the test suite, invoke the server, etc.) from the project's `CLAUDE.md`. Projects must document these conventions explicitly — the agent does not infer or guess commands.

### Storage

The execution layer extends the planning layer's plan folder with an additional file:

```
./sous-chef/plans/
  0001_user-authentication/
    prd.md
    roadmap.md
    impl.md        ← written by the execution agent before coding starts
```

`impl.md` contains the low-level breakdown: files to create or modify, method signatures, migration details, and the ordered list of TDD cycles. It is updated as work progresses.

### Commands

| Command | Purpose |
|---|---|
| `/chef:solve-issue <issue-number>` | Main entry point. Fetches the issue, reads the plan, writes `impl.md`, runs the TDD loop, passes the quality gate, and opens the PR. |

### CI and Post-PR

The execution layer exits when the PR is open and all local quality checks pass. CI monitoring and post-merge work are out of scope — those are owned by the quality/harness layer or handled manually.

### Exiting the Execution Layer

The execution layer exits when the PR is open and all quality gates pass. If the agent is interrupted mid-cycle, the `impl.md` checkpoint and the branch commit history allow the next session to resume from where it left off (via `/chef:handoff`).

---

## Quality Assurance Layer

The QA layer runs after the PR is opened. It starts with a clean context, reads the plan to understand intent, and exercises the feature from the outside — as a user would. Its job is to find what the execution layer could not see from the inside: gaps between what was planned and what was built, interaction bugs, security issues, and untested mutations.

### Agents

**QA Agent**
Starts from a clean context with no knowledge of how the feature was implemented. It reads only `prd.md` to understand what was intended, deliberately avoiding `impl.md` to prevent confirmation bias — if the implementation made a wrong assumption, reading it would obscure that fact.

The agent works through four areas in sequence:

**1. Manual testing**
Using the Playwright MCP, the agent exercises UI features in the browser and sends HTTP requests to test API endpoints. Test scenarios are derived entirely from the PRD — the agent tests what was asked for, not what was written. Before testing, the agent checks `CLAUDE.md` for environment startup instructions and brings up Docker/the Rails server if the app is not already running.

**2. Code review**
The agent reads the PR diff and reviews the implementation against the PRD. It looks for logic bugs, incorrect assumptions, missing edge case handling, and gaps between intent and execution.

**3. Security review**
The agent invokes the `security-review` skill to perform a manual-style security review of the changed code — auth gaps, mass assignment, insecure direct object references, and other vulnerabilities that automated scanners miss.

**4. Mutation testing**
The agent runs `mutant` scoped to the files and methods changed in the PR branch. Where mutant supports method-level filtering, the agent applies it to further narrow the scope. This is the only place mutant runs — it is not part of the execution quality gate.

### Findings and Report

After completing all four areas, the QA agent writes a report to the plan folder:

```
./sous-chef/plans/
  0001_user-authentication/
    prd.md
    roadmap.md
    impl.md
    qa_report_v1.md     ← first QA pass
    qa_report_v2.md     ← after execution fixes v1 findings
```

Each finding in the report includes:
- **Description** of the issue
- **Severity**: `critical`, `high`, `medium`, or `low`
- **Status**: `open`, `done`, or `discarded`

**Critical findings block the PR from merging.** All other severities are advisory — they inform but do not block.

Only you can mark a finding as `discarded`. The QA agent and execution agent cannot dismiss findings; they can only mark them `done` after a fix has been applied.

### The Execution→QA Loop

After the QA report is written, the execution agent reads it as a self-contained work queue. Open findings are treated like implementation tasks: the agent works through each one using its normal TDD loop, marks findings `done` as it resolves them, and commits the fixes.

Once execution finishes a pass, QA runs again. If execution made at least one fix, the new QA run produces the next versioned report (`qa_report_v2.md`, etc.). If no fixes were made, no new version is created.

You decide when to stop cycling. There is no automatic exit condition — the loop continues for as many passes as you invoke.

### Commands

| Command | Purpose |
|---|---|
| `/chef:review-pr <pr-number>` | Main entry point. Fetches the PR, reads `prd.md`, runs all four QA areas, and writes the versioned report. |

### Exiting the QA Layer

The QA layer exits after each report is written. Whether to continue the loop (invoke execution again, then QA again) is your decision. The loop is considered complete when you are satisfied with the state of the report — all findings are either `done` or `discarded`.

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
