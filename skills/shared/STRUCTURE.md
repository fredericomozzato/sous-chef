# Sous Chef — File Structure

Reference for all skills that read or write project files. When in doubt about where a file lives, consult this document.

---

## Directory layout

```
sous-chef/
  PRD.md                          ← app requirements (written by chef:interview)
  ARCHITECTURE.md                 ← stack and conventions (written by chef:interview)
  CHECKPOINT                      ← active milestone slug, one line (see below)
  milestones/
    NNN-slug.md                   ← milestone doc with inline slices (written by chef:milestone)
  issues/
    NNN-slug/                     ← one folder per milestone, named identically to its milestone file (minus .md)
      NNN.md                      ← expanded slice plan (written by chef:refine)
  reviews/
    NNN-slug/                     ← mirrors the issues folder structure (written by chef:qa)
      NNN/                        ← one folder per slice under review
        revision-N.md             ← QA findings; N increments on each re-review after chef:fix
```

---

## IDs and slugs

**Milestone ID (`NNN`):** three-digit zero-padded integer, auto-incremented from existing milestones. First milestone is `001`.

**Milestone slug:** lowercase, hyphenated version of the milestone title. Derivation rules:
- Lowercase everything
- Replace spaces and punctuation with hyphens
- Strip non-alphanumeric characters except hyphens
- Collapse consecutive hyphens into one
- Truncate to 40 characters if needed

Examples: "OAuth Authentication" → `oauth-authentication`, "2FA Setup" → `2fa-setup`, "User Posts: CRUD" → `user-posts-crud`. Milestone file: `001-oauth-authentication.md`.

**Slice number (`NNN`):** three-digit zero-padded integer, per-milestone, always starting at `001`. Slice numbers are sequential within a milestone and never reused.

---

## CHECKPOINT

A plain-text file at `sous-chef/CHECKPOINT`. It is the single source of truth for what is being worked on. Skills read it first — no file scanning needed.

**When a milestone is activated but no slice has been refined yet** (written by `chef:milestone`):
```
MILESTONE: 001-oauth-authentication
```

**When a slice is active** (written/updated by `chef:refine`, `chef:build`, `chef:qa`):
```
MILESTONE: 001-oauth-authentication
SLICE: 002
STATUS: IN_PROGRESS
```

Rules:
- `MILESTONE` value is `NNN-slug` — **no `.md` extension**. Skills append `.md` when opening the milestone file.
- `SLICE` value is the zero-padded three-digit slice number (e.g. `002`). Absent when no slice has been activated yet.
- `STATUS` is always uppercase: `IN_PROGRESS`, `IN_REVIEW`, or `DONE`. Absent when no slice has been activated yet.
- Written when a milestone is activated; updated at every slice status transition.
- If CHECKPOINT is absent, there is no active milestone. If SLICE is absent, no slice has been refined yet.

---

## Milestone file

`sous-chef/milestones/NNN-slug.md`

```markdown
---
id: "NNN"
name: slug           # machine-readable slug, not the display title (e.g. oauth-authentication)
status: PENDING | IN_PROGRESS | DONE
---

# Milestone title

Scope and context paragraph.

Any cross-cutting constraints.

## Slices

### Slice NNN — Name
STATUS: PENDING | IN_PROGRESS | IN_REVIEW | DONE

Delivers: {user-visible outcome}

Scope:
- {what gets built — intention, not implementation}
```

---

## Issue file

`sous-chef/issues/NNN-slug/NNN.md`

Written by `chef:refine`. Contains the full implementation plan for a single slice: files to touch, schema changes, test cases by name. This is the only place where implementation details live.

Frontmatter uses uppercase status values:
```yaml
---
status: IN_PROGRESS
branch: feat/{milestone-slug}/{slice-NNN}-{slice-slug}
slice: "{slice-NNN}"
milestone: "{NNN-slug}"
---
```

Status transitions: `IN_PROGRESS` → `IN_REVIEW` (by `chef:build`) → `DONE` (by `chef:qa`).

---

## Review file

`sous-chef/reviews/NNN-slug/NNN/revision-N.md`

Written by `chef:qa`. Contains findings from reviewing an IN_REVIEW slice. Revision number increments each time `chef:qa` re-reviews after `chef:fix` resolves findings.

---

## Slice status lifecycle

```
PENDING → IN_PROGRESS → IN_REVIEW → DONE
(refine)   (build)        (qa)     (qa: clean pass)
```

Milestone STATUS follows from its slices:
- `PENDING` — no slices started yet
- `IN_PROGRESS` — at least one slice is not DONE
- `DONE` — all slices are DONE
