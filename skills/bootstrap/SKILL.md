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
| `## App` → `Ruby version` (if present) | `--ruby={version}` (omit flag to resolve dynamically) |
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

If the script exits non-zero with a "Could not resolve Ruby version" message, ask the user via `AskUserQuestion`:

> *"bootstrap.sh could not determine the latest Ruby version automatically (curl or jq unavailable, or endoflife.date unreachable). Which Ruby version should we use? (e.g. 3.4.2)"*

Then retry the script with the explicit `--ruby={version}` flag. For any other non-zero exit, relay the error verbatim and stop.

---

## Step 4 — Verify and report

On success, run:

```bash
git log --oneline -1
```

Confirm the message is `chore: initial rails setup`. If it is not, tell the user the commit is missing and ask them to check the script output.

Then print a structured summary using the values already in memory from Step 3:

```
Bootstrap complete.

  App:        {name}
  Ruby:       {ruby version}
  Auth:       {auth}
  Jobs:       {jobs}
  CSS:        {css}
  Frontend:   {frontend}
  Uploads:    {uploads}
  Commit:     chore: initial rails setup ✓

Start the server:   make run
Stop the server:    make stop
Run tests:          make test
Open a shell:       make shell

Next step: run /chef:milestone to plan your first milestone.
Tip: run /clear to free up context first.
```
