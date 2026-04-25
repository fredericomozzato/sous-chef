#!/usr/bin/env bash
cat <<'EOF'
Workflow
════════════════════════════════════════════════════════════════════════════════

  mise-en-place → interview → milestone → refine → build → qa → fix → deliver
                                  ↑                                      ↓
                                  └──────────────── next slice ──────────────┘

  /chef:status can be run at any time to check where you are.

── Setup ────────────────────────────────────────────────────────────────────────

  /chef:mise-en-place    One-time bootstrap per project. Creates sous-chef/
                         structure and installs the SessionStart hook.

  /chef:interview        Gather requirements via interactive Q&A. Writes
                         PRD.md and ARCHITECTURE.md.

── Main loop (one iteration per slice) ──────────────────────────────────────────

  /chef:milestone        Plan the next milestone — a scoped set of vertical
                         slices. Requires PRD.md + ARCHITECTURE.md.

  /chef:refine           Expand the next PENDING slice into a detailed
                         implementation plan. Sets CHECKPOINT.

  /chef:build            Implement the IN_PROGRESS slice step by step with
                         TDD. Runs the quality gate on finish.

  /chef:qa               Review the IN_REVIEW slice. Writes a revision file
                         if findings exist; marks DONE if clean.

  /chef:fix              Resolve OPEN findings in the active revision, highest
                         severity first. Returns to /chef:qa when done.

  /chef:deliver          Ship the DONE slice as a PR. Handles screenshots,
                         quality score, draft approval, and CHECKPOINT reset.

── Utilities ────────────────────────────────────────────────────────────────────

  /chef:status           Report milestone progress and recommend the next
                         command. Read-only. Run at any time.

  /chef:browser-testing  Optional Playwright smoke test for the active slice.
                         Appends UI findings to the open revision.

  /chef:handoff          Save a session snapshot before stepping away.
                         Auto-loaded on the next session start.

  /chef:critic           Run RubyCritic and compare against the project
                         minimum. Called automatically by /chef:deliver.

  /chef:help             Print this reference.

── Slice lifecycle ───────────────────────────────────────────────────────────────

  PENDING → IN_PROGRESS → IN_REVIEW ⇄ fix → DONE
  (refine)   (build)        (qa)             (qa clean)

EOF
