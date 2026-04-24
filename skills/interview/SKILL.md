---
name: chef:interview
description: Gather feature requirements through interactive Q&A, then write PRD.md and ARCHITECTURE.md in sous-chef/.
---

# Interview

Gather requirements through focused conversation, then produce `sous-chef/PRD.md` and `sous-chef/ARCHITECTURE.md`.

**Usage:** `/chef:interview` or `/chef:interview [description of what you want to build]`

## Core rules

- **Use `AskUserQuestion` for every question.** Never dump a wall of text expecting inline replies. Group related questions — max 4–5 per turn.
- **Never ask open-ended "what do you prefer?" about things you have expertise on.** When the user is uncertain, present 2–3 concrete options with a recommended default and a one-line rationale. This is the thesis of the skill.
- **Never invent requirements.** If "standard Rails stuff" is vague, ask what it means here.
- **Do not write files until ~95% confident.** Write both files in one pass after explicit confirmation.
- **If `sous-chef/PRD.md` already exists**, stop and ask the user whether to overwrite, merge, or abort.

---

## Step 1 — Frame

**If the user passed a description inline** (e.g. `/chef:interview My app lets users...`), treat that text as the answer to the opening question and proceed directly to targeted follow-ups in Step 2.

**Otherwise**, ask one open-ended question via `AskUserQuestion`:

> *"What are we building? Give me an overview — features, users, the problem it solves. Write as much or as little as you like; I'll ask targeted follow-ups after."*

Do not ask for the project name here. Extract it from the user's answer if mentioned; otherwise ask for it in Step 2.

## Step 2 — Requirements

Work through the topics below with targeted `AskUserQuestion` calls. If the project already exists, read `Gemfile` and `package.json` first — do not ask about decided things.

**Project name** — if not already mentioned, ask: *"What should the app be called? This becomes the Rails app name and working directory (e.g. `my-app` → directory `my-app/`, constant `MyApp`)."* Capture both the slug form (lowercase-hyphenated) and the CamelCase constant form. Write both into `## App` in ARCHITECTURE.md.

**Product**
- Users: roles, goals, technical level, permission tiers
- Must-have features for first usable version
- Explicitly out of scope
- Anything already partially built

**UI / UX** _(skip if API-only)_
- Key screens / critical flows
- Device target: desktop, mobile-first, both
- Accessibility or layout constraints

**Data model**
- Main entities and relationships
- Non-obvious constraints (soft deletes, multi-tenancy, polymorphic, external IDs)

**Stack** — confirm or recommend per layer:

| Layer | Default |
|-------|---------|
| Rails | read Gemfile or ask |
| Database | PostgreSQL |
| Auth | Devise / Rodauth / custom / none |
| Authorization | Pundit / Action Policy / none |
| Background jobs | Solid Queue / Sidekiq / none |
| Frontend | Hotwire / React / ViewComponent |
| CSS | Tailwind |
| File uploads | Active Storage / Shrine / none |

**Validation layer (chef default)** — disclose and confirm:

> Sous Chef's default validation stack: **RSpec + SimpleCov + Mutant** (testing), **RuboCop + RubyCritic** (quality), **Brakeman + bundler-audit** (security), **database_consistency + strong_migrations** (DB integrity). This is what `/chef:build`, `/chef:qa`, and `/chef:critic` are built around. Deviating means some quality-gate skills may not apply. Accept the default or customize?

Record deviations in `ARCHITECTURE.md` under a **Validation** section.

## Step 3 — Visual design

Skip entirely for API-only apps.

Approach with real UI/UX judgment: propose directions, show concrete options, guide to decisions.

**3a — Direction.** Ask about mood (calm/warm/bold/minimal), existing brand constraints, and reference apps the user admires.

**3b — Specifics.** Based on the direction, propose concrete choices (not open questions) for:
- **Palette** — primary, surface, accent, status, text hierarchy. Name colors with intent, not hex codes.
- **Typography** — one heading face, one body face. Default to Inter + system-ui unless the mood calls for something distinctive.
- **Layout** — top nav / sidebar / centered column / split-panel. Match to primary use case.
- **Component library** (Tailwind projects) — shadcn/ui is the default recommendation; mention Flowbite/DaisyUI only if relevant.
- **Dark mode** — ask only if the app type warrants it.

**3c — Synthesize.** Output the brief as a plain markdown list in your text reply — no boxes, panels, or formatted widgets. Then use `AskUserQuestion` to ask for approval. Example format:

```
Design brief:
- Mood: calm, minimal
- Palette: slate background, indigo primary, zinc text hierarchy
- Typography: Inter (headings + body)
- Layout: centered column, top nav
- Components: shadcn/ui
- Dark mode: no
```

## Step 4 — Confirm

Summarize everything captured — app, users, MVP features, out of scope, stack, validation layer, visual direction, conventions — and ask for approval. Do not proceed until the user confirms. On significant corrections, update and re-confirm.

## Step 5 — Write

Run `scaffold.sh` first to create the directory structure and empty files:

```
scaffold.sh
```

Then write both files in one pass using the templates:
- `sous-chef/PRD.md` — see `prd-template.md`
- `sous-chef/ARCHITECTURE.md` — see `architecture-template.md`

Omit the Design section from PRD for API-only projects.

## Step 6 — Report

```
Interview complete.

  sous-chef/PRD.md          — {N} features documented, all PLANNED
  sous-chef/ARCHITECTURE.md — stack locked, conventions documented

Next step: run /clear and then /chef:bootstrap to scaffold the Rails app and install tooling.
```

If the user opted out of the default validation stack, flag that some chef quality-gate skills may not apply.
