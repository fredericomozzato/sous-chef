# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Sous Chef is a Claude Code plugin focused on Ruby on Rails development. It is a lightweight, token-efficient alternative to heavier frameworks like GSD and Openspec. The goal is to aggregate custom tools and workflows into a single plugin that enables predictable Rails prototyping without excessive token usage.

The name comes from the "sous chef" metaphor: the AI agent assists the developer (the "head chef") rather than taking over.

## Design Philosophy

- **Token efficiency is a core constraint.** Verbosity is a bug, not a feature. Every skill, prompt, and workflow should do more with less.
- **Rails omakase.** This plugin enforces conventions rather than offering flexibility. It is opinionated by design, targeting a specific stack and workflow, not a general-purpose tool.
- **Convention over configuration.** Workflows should be predictable and repeatable. Avoid footguns and open-ended options where a clear Rails convention exists.

### IMPORTANT
We should always try to optimize for token efficiency. This plugin is supposed to retain as much quality while using fewer tokens. Every optimization we can add to the skills and workflow to save tokens should be studied and tested until we find a sweet spot.

## Target Stack

Ruby on Rails applications. Skills and workflows should assume Rails conventions (MVC, ActiveRecord, Hotwire, etc.) unless otherwise specified.

## Project Status

Early-stage / WIP. The repository currently contains only documentation. Implementation of skills and workflows is ongoing.

## Plugin Conventions

### Skill invocation namespace
The plugin is registered under the name `chef` (see `.claude-plugin/plugin.json`). When referencing this plugin's skills from within other skills, always use the `chef:` namespace prefix — e.g., `/chef:create-pull-request`. Omitting the prefix or using a different namespace will cause the invocation to fail.

### `bin/` scripts are on PATH
Claude Code automatically adds the plugin's `bin/` directory to PATH when the plugin is enabled. Scripts placed there (e.g., `bin/pre-commit-checks.sh`) can be invoked by bare name — `pre-commit-checks.sh` — without a path prefix. Do not hardcode `bin/` in skill instructions.

### Invoking `bin/` scripts in skills — required format

**CRITICAL:** A fenced `bash` block alone is not sufficient. The agent may still construct an absolute path to the skill directory and fail with "no such file or directory". You must also tell the agent explicitly that the script is on PATH.

Required pattern — include the inline comment and the prose note:

```
Run the script. It is on PATH via the plugin's `bin/` directory — do not construct a path to it:

\```bash
script.sh  # on PATH via plugin bin/
\```
```

Wrong — causes "no such file or directory" errors even with a bash block:
```
Run `script.sh`.

\```bash
script.sh
\```
```

### `bin/` scripts run on the host, not inside Docker

Scripts in `bin/` are host-side orchestrators. They may call `docker compose` internally, but they must never be wrapped in `docker compose exec web …`. Wrapping them in Docker breaks `git` calls and nested `docker compose` invocations inside the script.

Correct: `pre-commit-checks.sh`
Wrong: `docker compose exec web pre-commit-checks.sh`

### Never edit the plugin install directory

**CRITICAL:** All changes to this plugin must be made in the repo at `/Users/frederico/development/sous-chef`. Never edit files under `~/.claude/plugins/` — that is a read-only install cache that gets overwritten on plugin updates. Changes made there are lost and bypass version control entirely.

## Git workflow

**CRITICAL:** Never make changes directly on `main`. Always create a feature branch first, then make changes, commit, push, and open a PR. `main` is the merge target, not the working branch.

```bash
git checkout main && git pull
git checkout -b fix/your-branch-name
# make changes, then:
git push -u origin fix/your-branch-name
gh pr create ...
```

## Versioning

This plugin uses semantic versioning (`MAJOR.MINOR.PATCH`):
- **PATCH** — bug fixes, typos, non-functional changes
- **MINOR** — new features, backwards-compatible (new skills or meaningful new capability in existing skills)
- **MAJOR** — breaking changes to existing skill interfaces

**Always bump `plugin.json` `version` as part of any feature branch** — do not wait to be reminded. Determine the correct increment from the rules above and apply it before committing your changes.

PRs are always **squash-merged**. Never push version tags from a feature branch — the squash discards those commits and the tag will point to a dangling commit. Always tag on `main` after the merge — and **never push a tag autonomously**. After the PR is merged, remind the user to tag and wait for explicit instruction before running:

```bash
git checkout main && git pull
git tag vX.Y.Z && git push origin vX.Y.Z
```
