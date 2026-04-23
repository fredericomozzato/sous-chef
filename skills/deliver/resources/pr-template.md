# PR Template — Slice Delivery

Use this template when writing the PR description in `chef:deliver`. Populate each section from the slice's issue file — do not leave placeholder text in the final description.

---

```markdown
Closes #{issue_number}
<!-- If the slice was not derived from a GitHub issue, remove this line entirely -->

## Summary

- {N bullet-points describing what the slice delivers — user-visible outcomes, not implementation details}

## Test Plan

- [ ] {discrete verification step}
- [ ] {discrete verification step}
- [ ] {discrete verification step}

## Screenshots

{Caption describing what is shown}

<!-- IMAGE: 001_state_description.png -->

{Caption describing what is shown}

<!-- IMAGE: 002_state_description.png -->
```

The `## Screenshots` section is **only included when the slice has UI changes**. Omit it entirely for API-only or non-visual slices.

---

## Authoring rules

**Summary** — write from a user perspective, not an implementation one:
- Good: "Users can register with email and password"
- Bad: "Added Devise gem and ran migration for users table"

Source the bullets from the scope section of the issue file (`sous-chef/issues/{MILESTONE}/{SLICE}.md`). Each bullet should be something the reviewer can confirm by using the app or reading the code.

**Test Plan** — each item must be a discrete, independently checkable step. Source them from the `Verification` section of the issue file. If the issue lists commands, include them verbatim:
- Good: `- [ ] Run \`rspec spec/requests/sessions_spec.rb\` — all examples pass`
- Good: `- [ ] Visit /login and submit valid credentials — redirects to dashboard`
- Bad: `- [ ] Tests pass`
- Bad: `- [ ] Feature works correctly`

Aim for 3-6 items. Cover the happy path, at least one edge/error case, and the RSpec suite.

**Never** mention AI, agents, or tooling names anywhere in the body. Write as a developer.

## PR title rules

Type MUST be uppercase, surrounded by square brackets. Allowed types:

| Type | When to use |
|------|-------------|
| `[FEAT]` | New user-facing feature |
| `[FIX]` | Bug fix |
| `[CHORE]` | Infrastructure, config, tooling |
| `[REFACTOR]` | Code restructuring with no behaviour change |
| `[TEST]` | Tests only |
| `[AGENTS]` | Skills, workflows, AI tooling |

After the type, write a concise description of the **slice** in sentence case. No colon, no dash.

Good: `[FEAT] Add email and password registration`
Bad: `feat: add registration`, `[FEAT]: Add registration`, `[FEAT] - add registration`

The title describes this slice specifically — not the milestone as a whole.
