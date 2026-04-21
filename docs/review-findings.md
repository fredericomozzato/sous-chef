# Skills System Review — Findings

Status markers: `[ ]` open · `[x]` done · `[-]` discarded

---

## Bugs — Flow-Breaking

**1. `chef:qa` clean pass never commits status updates** `[x]`

`chef:qa` Step 7 updates three files when the slice is clean (CHECKPOINT → `DONE`, issue frontmatter → `DONE`, milestone slice → `DONE`) but has no commit step. Compare to `chef:build` Step 8, which explicitly commits the status files. Without a commit, these updates sit as unstaged working tree changes. When `chef:deliver` pushes the branch, the DONE state is never included in the PR — the slice appears perpetually `IN_REVIEW` in git history.

Fix needed: Add a commit step to `chef:qa` Step 7, mirroring `chef:build` Step 8's pattern.

---

**2. Multiple `IN_PROGRESS` revision files possible** `[x]`

`chef:fix` Step 2 says "find the one with `status: IN_PROGRESS`" — but there's no tie-breaking rule if there are multiple.

This happens when `chef:browser-testing` runs before `chef:qa` (which the skill permits — it accepts any STATUS including `IN_PROGRESS`). Browser-testing creates revision-1 (IN_PROGRESS). Then `chef:qa` runs, counts existing files, creates revision-2 (IN_PROGRESS). Now `chef:fix` finds two open revisions with no guidance on which to pick.

Fix needed: Either prevent `chef:browser-testing` from creating a new revision if one already exists for a different phase, or add a tie-breaking rule to `chef:fix` (e.g., always pick the highest-numbered one).

---

## Significant Inconsistencies

**3. `chef:deliver` bypasses the RubyCritic gate that `chef:create-pull-request` requires** `[x]`

The legacy flow (`chef:create-pull-request`) is gated on:
- `bundler-audit`
- `chef:critic` (RubyCritic score comparison + `.rubycritic_minimum_score` update)

The new flow (`chef:deliver`) only runs `pre-commit-checks.sh`. Unless `pre-commit-checks.sh` already includes both of those, milestone-based PRs bypass the full quality gate. The two workflows produce PRs at different quality standards from the same project.

Fix needed: `chef:deliver` Step 3 (or a Step 2.5) should mirror the quality checks from `chef:create-pull-request` Step 0, or the two PR templates should explicitly align on what's required.

---

**4. Commit message style conflict between the two workflows** `[x]`

- `chef:build`: `feat(001-auth-setup/001): <desc>` (conventional commits)
- `chef:solve-issue`: Imperative sentence-case with no prefix (`Add formatted_name method to User model`)

Both can run in the same project. The git history will have mixed styles depending on which workflow created the commit.

Fix needed: Pick one style and apply it consistently across both workflows.

---

**5. `make rubycritic` vs `check-rubycritic.sh`** `[x]`

`chef:create-pull-request`'s "Updating an Existing PR Description" section says `run make rubycritic`. The legacy `pr-template.md` comment also says `Run make rubycritic`. But `chef:critic` runs `check-rubycritic.sh`. These are inconsistent references to what may or may not be the same command.

---

## Design Gaps

**6. No path to discard a finding** `[x]`

`revision-template.md` lists `DISCARDED` as a valid finding status. `chef:fix` ignores `DISCARDED` findings. But no skill has a step that allows the user to mark a finding `DISCARDED`. A developer who disagrees with a finding has no sanctioned path — they'd have to manually edit the revision file.

Fix needed: Add an explicit user-driven discard path to `chef:fix` (e.g., if pre-commit-checks keeps failing for a LOW/MED finding, offer the user the option to discard with a justification note in the revision file).

---

**7. `chef:milestone` and `chef:refine` don't commit their file writes** `[x]`

When `chef:milestone` activates a milestone it writes CHECKPOINT and updates the milestone frontmatter — neither is committed. `chef:refine` explicitly says "Do NOT commit." All these changes accumulate as unstaged working-tree modifications and get swept into `chef:build` Step 8's commit labeled `chore({MILESTONE}/{SLICE}): mark slice IN_REVIEW`. That commit will actually contain:
- CHECKPOINT activation (from milestone)
- Issue file creation (from refine)
- Milestone slice status → IN_PROGRESS (from refine)
- CHECKPOINT → IN_REVIEW (from build)

...all under a misleading message. This isn't a crash, but it makes git history harder to audit.

Fix needed: Either commit at the right handoff points (milestone activation, refine finalization) or document that all state files accumulate and are committed together by build.

---

**8. Screenshot naming conventions differ across three contexts** `[x]`

| Skill | Convention | Output folder |
|---|---|---|
| `chef:deliver` screenshot-flow | `{NNN}_{state}_{width}.png` | `tmp/pr/{MILESTONE}/{SLICE}/` |
| `chef:browser-testing` | `{NNN}_{state}.png` | `tmp/browser-testing/{MILESTONE}/{SLICE}/` |
| `chef:create-pull-request` | `{NNN}_{name}_{mode}.png` (light/dark) | `tmp/pr/draft_{brief_title}/` |

Three different conventions. A reviewer looking at `tmp/` would see screenshots from the same slice in two different folders with different naming patterns.

Fix needed: Align naming conventions and consider a single top-level folder under `tmp/screenshots/` or similar, scoped by milestone/slice.

---

**9. No branch guard in `chef:milestone`** `[x]`

After the last slice of a milestone is delivered, `chef:deliver` deletes CHECKPOINT via `git rm` on the feature branch. If the user runs `chef:milestone` before merging that PR and pulling main, they'll be on the feature branch with no CHECKPOINT. `chef:milestone` won't see a guard violation and will create a new milestone on the feature branch.

Fix needed: Add a guard that checks `git branch --show-current` and warns (not stops) if the user isn't on `main`.

---

**10. No status/next-step skill** `[x]`

There's no `chef:status` or equivalent that answers "what milestone/slice is active, what is its status, and what do I run next?" A user who's mid-workflow and opens a new session has to manually read CHECKPOINT and cross-reference the lifecycle. The `chef:handoff` skill loads context automatically, but only if the hook was configured by `chef:mise-en-place`.

Fix needed: A lightweight `chef:status` skill that reads CHECKPOINT and prints a concise summary + the next suggested command.

---

## Minor Notes

**11. `chef:deliver` doesn't persist the PR draft to disk** `[x]`

`chef:deliver` drafts the PR description in-memory and never persists it to disk (unlike `chef:create-pull-request` which writes to `tmp/pr/draft_.../description.md`). If something fails mid-creation, the draft is lost.

---

**12. `chef:deliver` PR template lacks `Closes #issue`** `[x]`

`skills/deliver/resources/pr-template.md` has no `Closes #issue` line. Slices derived from issues won't auto-close them.

---

**13. `chef:qa` clean-pass no-commit rule is undocumented** `[ ]`

`chef:qa` Step 8 says "Do not open a PR or commit" — the no-commit rule is explicit here but would benefit from a note explaining that `chef:fix` handles commits (to avoid confusion with the clean-pass case where no commit happens at all).

Note: this is related to finding #1. If #1 is fixed (adding a commit step to the clean pass), this note may become moot.
