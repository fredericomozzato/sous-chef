---
name: chef:bootstrap
description: Scaffold the Rails app, Docker environment, and tooling gems after /chef:interview completes.
---

# Bootstrap

Orchestrate the Rails scaffold by reading `sous-chef/ARCHITECTURE.md` and delegating all mechanical work to `bootstrap.sh`. All Rails commands run inside Docker — no local Ruby or Rails installation required.

## Core rules

- Run this exactly once per project, immediately after `/chef:interview`.
- Never run autonomously on a project that already has a `Gemfile`.
- Never rename directories or move files — directory decisions are the user's.
- If the script exits non-zero, relay its output verbatim and stop.

---

## Step 1 — Guard

Stop immediately if any condition fails:

| Condition | Error |
|---|---|
| `sous-chef/PRD.md` missing | "Run /chef:interview first." |
| `sous-chef/ARCHITECTURE.md` missing | "Run /chef:interview first." |
| `Gemfile` exists in CWD | "Rails app already exists here. Bootstrap only runs once." |
| `docker` not in PATH | "Docker is required. Install Docker Desktop and try again." |
| `docker info` fails | "Docker daemon is not running. Start Docker and try again." |

---

## Step 2 — Directory validation

Read `sous-chef/ARCHITECTURE.md`. Extract the `Name` field from `## App`.

Compare the CWD basename to `Name`:

| Situation | Action |
|---|---|
| CWD basename matches `Name` | Proceed silently |
| CWD is home dir, root, or `/tmp` | Stop — tell the user to navigate to the project directory |
| CWD basename differs, directory empty | Ask: "Current directory is `{cwd}` but the project is named `{name}`. Continue here, or should you cd first?" |
| CWD basename differs, directory not empty | Same question, note the directory is not empty |

Wait for the user's answer before proceeding.

---

## Step 3 — Parse and run

Read `sous-chef/ARCHITECTURE.md` silently. Map each `## Stack` row to a flag:

| Stack row | Flag |
|---|---|
| `## App` → `Name` | `--app-name={slug}` |
| `## App` → `Ruby version` (if present) | `--ruby={version}` (default: `3.3`) |
| Auth | `--auth=devise` / `--auth=rodauth` / `--auth=none` |
| Background jobs | `--jobs=sidekiq` / `--jobs=solid_queue` / `--jobs=none` |
| CSS | `--css=tailwind` / `--css=none` |
| Frontend | `--frontend=react` / `--frontend=hotwire` |
| File uploads | `--uploads=shrine` / `--uploads=active_storage` / `--uploads=none` |

Run:

```bash
bootstrap.sh --app-name={slug} --ruby={version} --auth={value} --jobs={value} --css={value} --frontend={value} --uploads={value}
```

The script logs each step as it runs. Let its output stream to the user — do not suppress or summarize it mid-run.

If the script exits non-zero, relay its last error message and stop.

---

## Step 4 — Report

On success, confirm:

```
Bootstrap complete. The script committed everything as "chore: initial rails setup".

Start the dev server:
  docker compose up

Next step: run /chef:milestone to plan your first milestone.
```
