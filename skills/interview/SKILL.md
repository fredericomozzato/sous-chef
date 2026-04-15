---
name: chef:interview
description: Gather feature requirements through interactive Q&A, then write PRD.md and ARCHITECTURE.md in sous-chef/.
---

# Interview

Gather requirements for the project through focused conversation, then produce the two foundational planning artifacts: PRD and Architecture.

**CRITICAL**
- Use `AskUserQuestion` for every question. Never dump a wall of text expecting the user to scroll and reply inline.
- Do not write any files until you have reached ~95% confidence in the requirements. When in doubt, ask.
- Never invent requirements. If something is unclear, ask. If the user says "standard Rails stuff", confirm what that means in this context.
- When the user is unsure about a technical decision, present concrete alternatives with a clear recommendation. Do not ask open-ended "what do you prefer?" questions about things you have expertise on.
- Write both files in a single pass after confirmation. Do not write one file, wait for feedback, then write the next.

---

## Step 1 — Open with a single framing question

Use `AskUserQuestion` to ask:

> What are we building? Give me a one-sentence pitch and the core problem it solves.

---

## Step 2 — Product and technical requirements

After the user's initial answer, analyze what you know and what you don't. Use `AskUserQuestion` to work through the topics below. Group related questions — never more than 4–5 per turn.

**When the user is uncertain about a technical choice, present options.** Show 2–3 concrete alternatives with a recommended default and a brief rationale. For example:

> For background jobs, you have a few good options:
> - **Solid Queue** — Rails 8 default, stores jobs in the database, zero extra infrastructure ✓ recommended
> - **Sidekiq** — fastest option, requires Redis, worth it at high volume
> - **None** — if you don't need async processing yet
>
> Which fits your situation?

This removes uncertainty and gets to a decision faster than asking "what do you want?".

---

### Topic checklist (all must be resolved before moving to Step 3)

#### Product
- Who are the users? (role, goals, technical level)
- Multiple user types with different permissions? (e.g., admin vs. member vs. guest)
- What are the must-have features for the first usable version?
- What is explicitly out of scope for now?
- Any features already partially built in this codebase?

#### UI / UX
- Does this app have UI views, or is it API-only?
- Key screens or flows that are critical to get right?
- Device target: desktop-only, mobile-first, or both?
- Any layout or accessibility constraints worth capturing?

#### Data model
- What are the main entities and how do they relate?
- Any non-obvious constraints? (e.g., soft deletes, multi-tenancy, polymorphic associations, external IDs)

#### Stack
Confirm or recommend for each layer. If the project already exists, read `Gemfile` and `package.json` first — do not ask about things already decided.

| Layer | Ask / check |
|-------|-------------|
| Rails version | Read from Gemfile or ask |
| Database | PostgreSQL (default), MySQL, SQLite |
| Auth | Devise, Rodauth, custom, none |
| Authorization | Pundit, Action Policy, none |
| Background jobs | Solid Queue (Rails 8 default), Sidekiq, none |
| Frontend | Hotwire (default), React, ViewComponent mix |
| CSS | Tailwind (default), plain CSS, other |
| File uploads | Active Storage (default), Shrine, none |
| Tests | RSpec + FactoryBot assumed; VCR? Capybara? |
| Any other already-decided dependencies | |

For undecided layers, present alternatives with a clear recommendation rather than leaving it open.

#### Validation layer (chef default — disclose and confirm)

Sous Chef ships with a standardized validation layer used across all projects. Disclose it to the user with `AskUserQuestion`:

> Sous Chef's default validation stack is:
>
> **Testing**
> - **RSpec** — test framework
> - **SimpleCov** — coverage reporting (enforces a minimum threshold)
> - **Mutant** — mutation testing (verifies tests actually catch bugs, not just execute code)
>
> **Code quality**
> - **RuboCop** (+ `rubocop-rails`, `rubocop-rspec`) — style and lint enforcement
> - **RubyCritic** — code quality scoring (tracks score over time, blocks PRs on regression)
>
> **Security & safety**
> - **Brakeman** — static analysis for Rails security vulnerabilities
> - **bundler-audit** — scans `Gemfile.lock` for gems with known CVEs
>
> **Database integrity**
> - **database_consistency** — flags mismatches between DB constraints and model validations/associations
> - **strong_migrations** — raises at boot time if a migration contains an unsafe operation (locks, missing indexes on large tables, etc.)
>
> This stack is the chef default — it's what the `/chef:build`, `/chef:qa`, and `/chef:critic` skills are built around.
>
> You're free to remove any tool or replace the whole stack — but deviating means some chef quality-gate skills may not apply. Do you want to use the default stack, or customize it?

- If the user accepts (or doesn't push back): proceed with the default. Document it in both files.
- If the user customizes: record their choices exactly. Note any deviations in `ARCHITECTURE.md` under a **Validation** section, and flag in the completion message that some chef quality-gate skills may not apply.

---

## Step 3 — Visual design (skip if API-only)

If the app has no UI views, skip this step entirely.

This step establishes the visual identity of the app. Its output is a **Design** section in `PRD.md` that every future slice uses as a reference when building views. Approach it with genuine UI/UX expertise — propose directions, show concrete options, and guide the user to decisions rather than asking open-ended questions.

### 3a — Establish the visual direction

Use `AskUserQuestion` to open the design conversation. Lead with mood and intent, not tooling:

> Let's talk about how this app should look and feel. A few things help me understand the visual direction:
>
> **Mood** — which of these resonates most?
> - Calm and focused (lots of whitespace, muted tones, clean typography) — good for productivity tools, dashboards
> - Warm and approachable (friendly rounded shapes, softer palette) — good for consumer apps, communities
> - Bold and direct (high contrast, strong type, confident colors) — good for tools, developer-facing apps
> - Minimal and invisible (the UI stays out of the way) — good for content-first or data-heavy apps
>
> **Existing brand** — does the app need to match existing brand colors or a logo, or is this greenfield?
>
> **References** — any apps or sites whose visual style you admire? Even one example helps.

### 3b — Drill into specifics

Based on the user's response, follow up on whichever of these remain unresolved. Group them — never more than 3–4 per turn.

**Color palette**
When the direction is clear, propose a concrete palette. Present it as a named set with intent, not hex codes:
- Primary action color (buttons, links, highlights)
- Surface colors (background, card, sidebar)
- Status colors (success, warning, error, info)
- Text hierarchy (heading, body, muted/caption)

Example proposal:
> Based on "calm and focused", here's a direction:
> - **Primary:** slate blue — professional, trustworthy, not cold
> - **Surface:** off-white base, light gray cards — reduces eye strain, easy to read
> - **Accent:** amber — warm highlight for CTAs and active states
> - **Status:** standard green/yellow/red
>
> Does this feel right, or do you want to shift tone? (e.g., cooler, darker, more saturated)

**Typography**
Propose a type pairing suited to the mood. Keep it simple — one heading face, one body face:
> - **Headings:** Inter or Geist — neutral, highly legible at all sizes
> - **Body:** system-ui stack — fastest load, familiar, consistent across OS
>
> Or, for a more distinctive feel: a serif heading (e.g., Playfair, Lora) with a neutral body.

**Layout pattern**
Match the layout to the app's main use case:
- **Top nav + content area** — universal, good default for most apps
- **Sidebar + main panel** — right for dashboards, admin tools, multi-section apps
- **Centered narrow column** — great for content-first or form-heavy apps
- **Split-panel** — left/right views, good for list-detail patterns

**Component library**
For Tailwind projects, recommend one of:
- **No library, utility-first** — full control, zero bloat, right for experienced teams
- **shadcn/ui** — unstyled primitives you own; excellent accessibility baseline ✓ recommended for most projects
- **Flowbite** — more opinionated, faster to start, less flexible
- **DaisyUI** — Tailwind plugin with pre-built components, fastest for prototypes

**Dark mode**
Ask only if the app warrants it (productivity tools, dev tools, dashboards often do; marketing sites rarely do):
> Does this app need dark mode support from day one?

### 3c — Synthesize into a design brief

Once the design direction is clear, use `AskUserQuestion` to confirm the brief before writing:

> Here's the visual direction I'll document:
>
> **Mood:** [e.g., calm and focused]
> **Palette:** [e.g., slate blue primary, off-white surface, amber accent]
> **Typography:** [e.g., Inter headings, system-ui body]
> **Layout:** [e.g., sidebar + main panel]
> **Components:** [e.g., shadcn/ui on Tailwind]
> **Dark mode:** [yes / no]
>
> Does this match what you have in mind?

---

## Step 4 — Confirm understanding before writing

Use `AskUserQuestion` to present a full summary for approval:

> Before I write the docs, here's everything I've captured:
>
> **App:** [one-line summary]
>
> **Users:** [who, roles]
>
> **MVP features:**
> - [feature name] — [one sentence]
> - ...
>
> **Out of scope:** [list]
>
> **Stack:** Rails [version], [auth], [frontend], [jobs], [CSS]
>
> **Validation layer:** [default / custom — list any deviations]
>
> **Visual direction:** [mood, palette, layout, components] _(omit if API-only)_
>
> **Conventions I'll document:**
> - [e.g., Pundit policies on all controller actions]
> - [e.g., Turbo Streams for all form submissions]
>
> Anything to add or correct before I write the docs?

Do not proceed until the user confirms. If they make significant corrections, update your understanding and re-confirm.

---

## Step 5 — Write the artifacts

Write both files in one pass.

### 5a — `sous-chef/PRD.md`

```markdown
# PRD — {App Name}

{One-paragraph description: what the app does, the problem it solves, who uses it.}

---

## Users

{One paragraph or bullet list per user type. Include: role, goals, technical level, and any permissions that differ from others. If there's only one user type, say so.}

---

## Features

### {Feature name}
STATUS: PLANNED

{2–4 sentences: what this feature does and why it matters to the user.}

**Scope:**
- {concrete, testable scope item}
- {concrete, testable scope item}

**Out of scope:**
- {anything explicitly excluded from this feature}

{Repeat for each feature.}

---

## UI / UX

{Describe key screens and user flows in prose and bullets. Note layout constraints, responsive requirements, or interaction patterns that are not self-evident from the feature list.}

---

## Design

_Omit this section entirely for API-only projects._

### Visual direction

{One sentence capturing the mood and intent. e.g., "Calm and focused — minimal chrome, generous whitespace, the data is the hero."}

### Color palette

| Role | Color / description |
|------|-------------------|
| Primary | {e.g., Slate blue — actions, links, active states} |
| Surface | {e.g., Off-white base, light gray cards} |
| Accent | {e.g., Amber — CTAs, highlights} |
| Success / Warning / Error | {e.g., Standard green / yellow / red} |
| Text | {e.g., Near-black headings, medium gray body, light gray captions} |

### Typography

| Role | Choice |
|------|--------|
| Headings | {e.g., Inter, 600–700 weight} |
| Body | {e.g., system-ui stack, 400 weight} |
| Code / mono | {e.g., JetBrains Mono, if needed} |

### Layout

{Describe the dominant layout pattern and why it fits the app. e.g., "Sidebar + main panel: the app has multiple sections and users switch between them frequently."}

### Component library

{Choice and rationale. e.g., "shadcn/ui on Tailwind — unstyled primitives the codebase owns, strong accessibility baseline."}

### Dark mode

{Yes / No, and if yes, any constraints.}

---

## Data Model

### {Entity name}

| Field | Type | Notes |
|-------|------|-------|
| ...   | ...  | ...   |

{Relationships in prose. Skip `id`, `created_at`, `updated_at` unless they carry special semantics.}

{Repeat for each entity.}

---

## Out of scope (MVP)

{Consolidated list of deferred features and behaviors. Parking lot for "nice to haves".}
```

### 5b — `sous-chef/ARCHITECTURE.md`

```markdown
# Architecture — {App Name}

---

## Stack

| Layer | Choice | Notes |
|-------|--------|-------|
| Ruby on Rails | {version} | |
| Database | {choice} | |
| Auth | {choice} | {why, if non-default} |
| Authorization | {choice} | {why, if non-default} |
| Background jobs | {choice} | {why, if non-default} |
| Frontend | {choice} | |
| CSS | {choice} | |
| Component library | {choice} | {why, if non-default} |
| File uploads | {choice} | |
| Tests | RSpec + FactoryBot + SimpleCov + Mutant | |
| Linting | RuboCop + rubocop-rails + rubocop-rspec | |
| Code quality | RubyCritic | |
| Security | Brakeman + bundler-audit | |
| DB integrity | database_consistency + strong_migrations | |
| {other dep} | {library} | {why} |

---

## Conventions

{Short, prescriptive rules every slice must follow. Standard Rails MVC, ActiveRecord, and RESTful routes are assumed — do not repeat them.}

**Authorization**
- {e.g., All controller actions are covered by a Pundit policy. No inline `if current_user.admin?` checks in controllers or views.}

**Frontend**
- {e.g., All form submissions use Turbo Streams. No full-page reloads for user-initiated actions.}
- {e.g., Stimulus controllers handle all JS behaviour. No inline scripts.}

**Testing**
- {e.g., Request specs for all controller actions — no controller specs.}
- {e.g., System specs for critical user flows only. Unit/integration ratio target: 80/20.}
- {e.g., FactoryBot for all test data. No fixtures.}

**Service objects**
- {e.g., Business logic that spans more than one model lives in `app/services/`. Named `VerbNounService`. Returns a result object, never raises.}

{Add or remove sections as needed.}

---

## Decisions

{Decisions that required trade-off analysis or that a future developer might question.}

**{Decision title}** — {what was chosen}, {what was rejected}, {why}.

{Repeat for each non-obvious decision.}
```

---

## Step 6 — Confirm completion

After both files are written, report to the user:

```
Interview complete.

  sous-chef/PRD.md          — {N} features documented, all PLANNED
  sous-chef/ARCHITECTURE.md — stack locked, conventions documented

Next step: run /chef:roadmap to break the PRD into slices.
```
