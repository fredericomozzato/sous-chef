---
name: solve-issue
description: Fetches a GitHub issue by number and implements a solution. Covers the full workflow from branching, implementation, testing, pre-commit checks, to PR creation.
argument-hint: <issue-number>
disable-model-invocation: true
---

# Solve Issue Skill

This skill defines the mandatory process for implementing GitHub issues in this repository.
All agents MUST follow this process exactly when requested to implement an issue.

**CRITICAL**
- Follow the EXACT steps defined in this document. DO NOT skip any steps. This is a mandatory process.
- Follow the steps in the correct order. DO NOT jump to a step without completing the previous one.
- If you believe you can skip a step you STOP. This is rationalization. Follow the steps defined in this document.
- Follow all the PR description validation requirements (e.g., waiting for user approval of the description).

## Arguments

These placeholders are substituted by the skill runner at invocation time. For example, `/chef:solve-issue 42 use Turbo Streams` substitutes `$0` → `42` and `$ARGUMENTS` → `42 use Turbo Streams` (the full argument string):

- **Issue number**: `$0`
- **Additional instructions**: `$ARGUMENTS`

Apply any additional instructions throughout the workflow where relevant.

## Step-by-Step Workflow

### Step 1: Fetch and Understand Issue Details
DO NOT SKIP THIS UNTIL IS DONE.
- Delegate the fetch to a lightweight parallel subagent (prefer Claude Haiku if available) to preserve context and save tokens. Instruct the subagent to return the full issue content (title, description, comments) without summaries or commentary.
  - Primary: use GitHub MCP to fetch issue #$0.
  - Fallback: if MCP is unavailable, use `gh issue view $0`.
- Ensure you fully understand the requirements before proceeding. If the issue is not clear, ask for clarification to the user. Use the `AskUserQuestion` tool if needed.

### Step 2: Create a Branch
DO NOT SKIP THIS UNTIL IS DONE.
You always MUST pull the most recent changes from `main` before creating a new branch. This is not optional.

Branch names MUST follow the format: `{type}/$0-{brief-kebab-case-title}`

Determine the correct type from the issue's title:
- `feat` — new feature or capability
- `fix` — bug fix
- `chore` — maintenance, dependencies, tooling
- `docs` — documentation only
- `refactor` — code restructuring without behavior change
- `test` — adding or fixing tests only
- `agents` - adding or updating agents configuration, skills, CLAUDE.md, etc.

The branch name must be in English. Example: `feat/99-implement-new-calculator-page`

```bash
git checkout main
git pull origin main
git checkout -b {type}/$0-{brief-kebab-case-title}
```

If you think you can start work before creating a branch, STOP. This is rationalization. Create the new branch BEFORE writing any code.

### Step 3: Implement the Solution
DO NOT SKIP THIS UNTIL IS DONE.
- Create an implementation plan before making any changes. Share it with the user for approval.
- Make the necessary code changes to fully resolve the issue.
- Ensure **100% test coverage** using RSpec.
- Use red → green → refactor TDD cycles to implement the solution.
- After each cycle, run `pre-commit-checks.sh` and commit if checks pass. Commit messages MUST follow these rules:
  - Written in **English**
  - **Imperative**, sentence-case format, no prefix
  - Good: `Add formatted_name method to Whey model`
  - Forbidden: `feat: added model`, `[FIX] the error`

### Step 4: Request User Review
DO NOT SKIP THIS UNTIL IS DONE.
Present your implementation to the user for review. Your review request MUST include:
- A summary of all changes made
- A list of every file modified
- An explicit request for approval before proceeding

Example message to the user:
```
Here's a summary of everything I implemented:

[List all changes and files modified]

Would you like me to proceed to the PR, or do you want any changes first?
```

DO NOT proceed until the user explicitly approves. If the user requests changes, implement them and re-run pre-commit checks before requesting review again.

For UI changes: the user must also visually approve the interface before you proceed to the PR step.

### Step 5: Create the Pull Request
DO NOT SKIP THIS UNTIL IS DONE.
You MUST use the `/chef:create-pull-request` skill to generate the PR.
- Make sure to indicate that the PR closes the issue in the description (e.g., "Closes #$0").

### Step 6: Notify the User
DO NOT SKIP THIS UNTIL IS DONE.
Notify the user that the issue has been successfully resolved, the code is committed, and the PR has been created. Include the link to the generated pull request in your final message.
