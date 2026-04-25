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

## Versioning

This plugin uses semantic versioning (`MAJOR.MINOR.PATCH`):
- **PATCH** — bug fixes, typos, non-functional changes
- **MINOR** — new skills or features, backwards-compatible
- **MAJOR** — breaking changes to existing skill interfaces

**Always bump `plugin.json` `version` as part of any feature branch** — do not wait to be reminded. Determine the correct increment from the rules above and apply it before committing your changes.

PRs are always **squash-merged**. Never push version tags from a feature branch — the squash discards those commits and the tag will point to a dangling commit. Always tag on `main` after the merge — and **never push a tag autonomously**. After the PR is merged, remind the user to tag and wait for explicit instruction before running:

```bash
git checkout main && git pull
git tag vX.Y.Z && git push origin vX.Y.Z
```
