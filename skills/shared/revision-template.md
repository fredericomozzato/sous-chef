# Revision File — Template and Format Reference

Used by `chef:qa` and `chef:browser-testing` when writing or appending to revision files at `sous-chef/reviews/{MILESTONE}/{SLICE}/revision-N.md`.

---

## File template

```markdown
---
branch: {branch from issue frontmatter}
revision: N
status: IN_PROGRESS
milestone: "{MILESTONE}"
slice: "{SLICE}"
---

## Phase 1 — Build gate + completeness audit

<findings using flat inline format, or "No findings.">

## Phase 2 — Implementation review

<findings using flat inline format, or "No findings.">
```

Add `## Phase 3 — Browser Testing` after Phase 2 when `chef:browser-testing` contributes findings (either appended to an existing file or included in a new one).

---

## Flat inline finding format

```
**C1** · BLOCKER · OPEN · `app/models/article.rb`
RuboCop reports 3 offenses: frozen_string_literal missing (line 1), trailing whitespace (lines 4, 12).

**I1** · HIGH · OPEN · `app/controllers/articles_controller.rb:34`
`#destroy` has no authorization check. Any authenticated user can delete any record regardless of ownership. Affects `app/controllers/articles_controller.rb:34` and the corresponding request spec which does not assert the 403 case.

**U1** · MED · OPEN · `app/views/articles/index.html.erb`
Article list renders with no vertical spacing between entries at 375px. Title text overlaps the author line. Observed at http://localhost:3000/articles.
```

Findings state what is wrong and why — they never prescribe a fix.

---

## Finding ID prefixes

| Prefix | Source | Examples |
|--------|--------|---------|
| `C` | Phase 1 — completeness (chef:qa) | `C1`, `C2` |
| `I` | Phase 2 — implementation (chef:qa) | `I1`, `I2` |
| `U` | Phase 3 — browser testing (chef:browser-testing) | `U1`, `U2` |

IDs are sequential within each prefix and never reused within a revision file.

---

## Severities

`BLOCKER · HIGH · MED · LOW`

| Severity | When to use |
|----------|-------------|
| `BLOCKER` | App crash, unhandled exception, failing build check, 500 error |
| `HIGH` | Wrong behaviour, missing feature, broken authorization |
| `MED` | Missing test coverage, UI inconsistency, anti-pattern |
| `LOW` | Cosmetic issue, minor style deviation |

---

## Statuses

`OPEN · FIXED · DISCARDED`

- `OPEN` — finding is unresolved (written by chef:qa / chef:browser-testing)
- `FIXED` — finding was resolved (updated by chef:fix)
- `DISCARDED` — finding was intentionally dismissed (updated by chef:fix with user agreement)

---

## Frontmatter status lifecycle

`IN_PROGRESS` → `DONE`

- `IN_PROGRESS` — at least one finding is still `OPEN`
- `DONE` — all findings are `FIXED` or `DISCARDED` (set by chef:fix on the last finding)
