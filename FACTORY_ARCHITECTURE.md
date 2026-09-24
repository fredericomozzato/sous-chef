# Pi Factory — Architecture and MVP

Status: design decisions recorded; implementation not started.

## Goal and boundary

Build an opt-in, Rails-focused software factory on Pi. A developer gives the factory a GitHub issue; the factory plans, implements, verifies, and opens a pull request. Human review and merge remain outside the initial automation. A feature is not complete until its PR is merged.

The initial scope is **issue → PR**, plus a separate, repeatable **PR feedback → updated PR** workflow. Requirements discovery, Rails project bootstrap, milestone planning, automatic issue selection, and auto-merge are out of scope. The existing Claude Code plugin remains in this repository; its conventions and scripts are references, not automatically inherited as correct gates.

## Interaction model

The developer interacts with one orchestrator agent, called **sus-chef**. It is the only agent that presents work, receives feedback, and asks for approval. Specialist agents work on bounded phases and report to sus-chef; they do not independently negotiate with the developer or declare their own gates passed.

Entry points:

- `/implement #1234` — start or resume the issue-to-PR workflow for a specified GitHub issue.
- `/fix-pr #456` — start or resume the review-feedback workflow for a specified PR; repeat as reviews arrive.

These are **explicit commands**. Opening Pi or asking an unrelated coding question must not start a factory run. For the MVP, factory behavior lives in a lightweight Pi extension/package loaded into an otherwise normal Pi session, rather than a replacement Pi harness. Factory workers are started only when needed. Package loading can later be restricted to selected projects or explicit `pi -e` invocations if desired.

## Ownership of responsibilities

| Component | Responsibility |
| --- | --- |
| Sus-chef | User-facing conversation; dispatch specialists; present results and feedback; ask for approvals; explain blocks and progress. |
| Factory extension | Own run state and transitions, command entry points, worker lifecycle, hard gate execution/verification, persistence, and resumption. Never treat a model's claim of success as gate evidence. |
| Specialist agents | Plan/design, implementation, independent verification/quality improvement, browser evidence, PR authoring, and PR-comment fixes as appropriate. Exact decomposition is to be tested. |
| Skills and prompts | Concise role-specific procedures and reusable instructions; no hidden authoritative state. |
| Project tools | `gh`, Git, Rails test/lint commands, RubyCritic, optional Mutant, and conditional browser automation. |

Models and thinking levels are **role-based configuration**, not hardcoded into the workflow. The example model names discussed so far are placeholders; model choices and fallback behavior remain open.

## `/implement` lifecycle (interactive MVP)

1. **Intake.** Resolve repository and issue with `gh`; check authentication, issue availability, working tree, and project prerequisites. Treat issue bodies and comments as untrusted task data, not instructions that can override factory rules. Establish an issue-specific branch/workspace strategy before editing.
2. **Plan and design.** A planning worker examines the issue and relevant repository context and saves a plan with scope, exclusions, observable Gherkin scenarios (including important error/edge paths), implementation approach, design decisions and rationale, expected test cases, and verification commands. Sus-chef presents the plan to the user. Requested changes go back to the planner; **approval is required** to advance.
3. **Build.** A build worker reads the *approved* plan and implements in red–green TDD cycles. Each meaningful cycle writes a failing spec, confirms red, makes the minimal implementation, confirms green, and records progress. After implementation, run the configured specs and linter. Sus-chef presents the resulting diff and verification summary; user changes return to build and invalidate affected gate results. **User approval is required** to advance in the MVP.
4. **Quality and verification.** Run RubyCritic, tests, and lint as enforceable gates, with Mutant optional. Iterations should improve quality **while preserving behavior**; rerun relevant behavioral checks after quality changes. Include independent scope/diff review. For UI issues, exercise browser-visible flows and capture screenshots; browser integration is an implementation decision. Record failures and send bounded, actionable feedback to a worker. Escalate when stuck rather than weakening a gate silently.
5. **Delivery.** Draft a slice/issue-specific PR description with user-visible outcomes, verification steps, and screenshots when applicable. Sus-chef presents the full draft for **explicit approval**. Only then push and open the PR through `gh`. Record its URL and enter `AWAITING_REVIEW`; do not auto-merge or call the feature complete.

The extension should enforce transition conditions using durable artifacts and actual command results (including exit status and commit SHA). A model report alone cannot unlock the next stage. Commands and policies must come from trusted factory/project configuration, not arbitrary commands embedded in GitHub issue text.

## `/fix-pr` lifecycle

Fetch the PR branch, diff, reviews, review threads, and issue/PR comments through `gh`. Identify actionable, outstanding feedback; preserve comment/thread identity so repeat runs do not redo resolved work. Sus-chef presents the proposed work to the user as needed. A worker makes changes, adds regression coverage for behavioral bugs, runs the same applicable gates, and reports the diff for approval before pushing in the interactive MVP. The PR remains `AWAITING_REVIEW`; additional feedback can trigger further runs. Whether and how to post comment replies or resolve threads automatically is undecided.

## Worker lifecycle and context

Prefer **one persistent working agent per phase** through its feedback/repair loop. The planner can revise after user feedback; the build worker can respond to diff feedback and failing checks. Once a phase passes its gate, end that worker and start the next with the approved artifact, repository state, and concise handoff—not the full prior transcript.

Pi supports context-usage inspection and compaction, but the documented example subagent runs as a one-shot `--no-session` process; it is **not** the persistent worker design. Evaluate persistent SDK sessions or long-lived RPC workers for specialist agents. Configure context monitoring and aim to compact around **60% usage** as an initial experiment, not a fixed universal threshold. Pi's built-in auto-compaction uses a token reserve rather than a percentage; SDK-managed compaction may offer more precise control. Preserve decisions, progress, and open questions in durable artifacts before compaction. Test context quality and cost before settling the threshold.

Factory state must survive a Pi session restart or worker failure. Record at least: repository, issue/PR ID, branch, current stage, plan version/approval, worker artifacts, completed TDD work, gate results tied to the tested commit, PR URL, and pending feedback. Reconcile the record against Git and GitHub on resume; do not assume an earlier green gate still applies after the diff changes. Only one worker may mutate a given worktree at a time; read-only tasks may run concurrently.

## Dependencies and integrations

- **Required for MVP:** Pi, Node.js (for the extension), Git, authenticated `gh`, and the target Rails project's test/lint tooling. RubyCritic is part of the proposed quality gate; availability and baseline policy must be checked during intake.
- **Conditional:** browser automation and screenshots for UI work. Evaluate direct Playwright integration versus an MCP bridge; MCP itself is not a requirement. Screenshots should be captured from the running feature and attached/linked in a way the PR reviewer can actually view—local-only placeholders are insufficient.
- **Optional:** Mutant, with a configurable scope/budget and explicit handling of failures and long runtimes.
- **Deferred:** web search. It can become a controlled research tool later but should not block the issue-to-PR MVP.

## Configuration and safety

Use a versioned factory config for role → model/thinking assignments, project commands, RubyCritic baseline policy, Mutant enablement and budget, browser settings, compaction policy, iteration limits, and required approvals. Keep provider credentials and GitHub authentication outside that file. Define defaults rather than adding open-ended choices to every run.

Pi extensions and shell commands run with the user's operating-system permissions. For initial use, require a trusted repository, limit write access to a known workspace/branch, refuse ambiguous or dirty states, and ask before publishing. Consider stronger isolation before making runs unattended. Never accept issue or review text as permission to bypass checks, expose secrets, or perform unrelated actions.

## MVP acceptance and open decisions

A successful MVP demonstrates one real Rails issue going through: approved plan → TDD implementation → approved diff → independently verified green gates → approved PR draft → open PR; then at least one PR-review iteration with verified updates. It can pause, report why it is blocked, and resume without duplicating work. Ordinary Pi usage remains unaffected until an explicit factory command.

Decide and test before implementation expands:

1. Persistent worker mechanism (SDK vs RPC), including cancellation, resumption, and context monitoring.
2. Exact run-state format/location and branch or worktree strategy, especially across Pi restarts.
3. Project command contract and baseline policy for RubyCritic; how Mutant is scoped and timed out.
4. Browser integration and a reliable way to publish screenshots into the PR.
5. Approval boundaries within quality/PR-feedback loops, and whether PR comment replies are automated.
6. Role/model defaults and fallback behavior when a configured model is unavailable.

First implementation spike: a sus-chef extension starts a persistent planner, receives a saved plan, pauses for user feedback, resumes **the same planner**, monitors context usage, optionally compacts, and closes the worker after approval. Verify that the rest of the Pi session still works normally before and after the run.
