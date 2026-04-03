# Sous Chef
A Claude Code plugin to streamline development focused on Ruby on Rails applications. The name was borrowed from the book Vibe Coding by Gene Kim and Steve Yegge where they compare the use of coding agents as having a sous chef helping us (the head chef) to achieve our vision.


## Purpose
I've been trying to use other frameworks like [GSD]() and [Openspec](). Both are **really** good, but I feel they're extremely verbose and kill my usage in almost no time (I use the pro plan, so not many tokens to spare per session).

Thinking about these limitations I decided to aggregate the tools I built over time into a single plugin to help me develop apps in a predictable way while not burning all my tokens in minutes.


## Why focus on Ruby on Rails?
This is the main tech stack that I use. Yes, coding agents can help us write code in any language and stacks, but this one is a lightweight framework to help with a more specific sstack, allowing me to create focused tools and workflows.

As Rails users we are kind of accostumed with the *omakase* approach... so I created this plugin to be just like that: a set of conventions that I use in my projects. Sous Chef will help quickly prototyping and testing Rails applications with a predictable infracstructure.

# Usage
The plugin is named Sous Chef, but I simplified the usage name to `chef` (less typing is always good).


# Features

## `/chef:create-issue`

Creates a GitHub issue following a structured workflow: gathers requirements, formats the title as `[TYPE] Brief description` (e.g. `[FEAT] Add calculator page`), determines the assignee interactively, writes a Markdown body with a problem description, definition-of-done checklist, and TDD execution instructions, then presents the draft for your approval before creating it.

**Usage:** `/chef:create-issue` — describe the issue when prompted, or include a description inline.

---

## `/chef:solve-issue <issue-number>`

Fetches a GitHub issue and implements a full solution end-to-end: creates a properly-named branch off `main`, implements the feature or fix with 100% RSpec test coverage using TDD (red → green → refactor), runs pre-commit checks after each cycle, requests your review before opening a PR, then delegates to `/chef:create-pull-request` to finalize.

**Usage:** `/chef:solve-issue 42` or `/chef:solve-issue 42 use Turbo Streams` to pass additional instructions.

---

## `/chef:create-pull-request`

Creates a pull request (or updates an existing PR description) with a full quality gate: runs `bundler-audit` (hard block on vulnerabilities), captures screenshots for UI changes, writes a description following the project template, waits for your explicit approval, then creates the PR via the GitHub MCP (fallback: `gh` CLI).

**Usage:** `/chef:create-pull-request` — invoke after your branch is ready to ship.
