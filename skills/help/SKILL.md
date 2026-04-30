---
name: chef:help
description: Use when the user runs /chef:help to print the command reference and workflow overview.
---

# Help — Command Reference

Read-only. Never writes or commits anything. No tool calls — print the reference below as your text response.

---

**Sous Chef** is a Claude Code plugin for Rails development. It guides you through a structured workflow — from requirements to shipped feature — with predictable, repeatable steps.

**Workflow** (run in order):

1. `/chef:mise-en-place` — One-time project setup. Creates the `sous-chef/` structure and installs the session hook.
2. `/chef:interview` — Gather requirements via Q&A. Writes `PRD.md` and `ARCHITECTURE.md`.
3. `/chef:bootstrap` — Scaffold the Rails app and Docker environment. Run once, right after interview.
4. `/chef:milestone` — Plan the next milestone as a set of vertical slices.
5. `/chef:refine` — Expand the next slice into a step-by-step implementation plan.
6. `/chef:build` — Implement the slice with TDD. Runs quality checks on finish.
7. `/chef:qa` — Review the built slice. Writes findings or marks it DONE.
8. `/chef:fix` — Resolve QA findings, highest severity first.
9. `/chef:deliver` — Ship the DONE slice as a PR. Repeat from step 5 for the next slice.

**Slice lifecycle:** `PENDING` → `IN_PROGRESS` → `IN_REVIEW` ⇄ `fix` → `DONE`

**Utilities (run any time):**

- `/chef:status` — Show current milestone progress and recommend the next command.
- `/chef:browser-testing` — Playwright smoke test for the active slice.
- `/chef:critic` — RubyCritic score check. Called automatically by `/chef:deliver`.
- `/chef:handoff` — Save a session snapshot before stepping away.
- `/chef:help` — Show this reference.
