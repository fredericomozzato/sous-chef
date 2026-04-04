---
name: chef:create-issue
description: Use when prompted to create a new GitHub issue in the repository.
disable-model-invocation: true
---

# Create Issue Skill

This skill defines the mandatory process for creating new issues in this repository.
All agents MUST follow this process exactly when requested to create an issue.

**CRITICAL**
- Follow the EXACT steps defined in this document. DO NOT skip any steps. This is a mandatory process.
- Follow the steps in the correct order. DO NOT jump to a step without completing the previous one.
- If you believe you can skip a step, STOP. This is rationalization. Follow the steps defined in this document.

## Step-by-Step Workflow

### Step 1: Gather Information and User Intent
DO NOT SKIP THIS UNTIL IS DONE.
- Understand what the issue is about, clarify the requirements with the human if necessary. Use the `AskUserQuestion` tool to gather more info if you do not understand the requirements.
- **Tip:** If the task requires creating the issue using MCP commands, delegate the issue creation tool call to cheaper, faster models (e.g., Gemini Flash, Claude Haiku) whenever possible to preserve tokens.

### Step 2: Determine Issue Title and Repository
DO NOT SKIP THIS UNTIL IS DONE.

#### Title
Issue names MUST follow this format:
`[TYPE] Brief description`

The allowed types are the same defined in the PR guidelines (e.g., `FEAT`, `FIX`, `CHORE`, `DOCS`, `REFACTOR`, `TEST`, `AGENTS`). **The type must be fully uppercase and enclosed in brackets.**

**Good examples:**
- `[FEAT] Implement new calculator page`
- `[FIX] Resolve nil pointer in Whey model`
- `[CHORE] Bump simplecov version`
- `[AGENTS] Update skills`

#### Project
Derive the target repository from the current project context:
- Primary: use GitHub MCP to get the current repository name.
- Fallback: if MCP is unavailable, use `gh repo view --json nameWithOwner --jq '.nameWithOwner'`.

### Step 3: Determine Assignee
DO NOT SKIP THIS UNTIL IS DONE.

The assignee depends on the task.
- If the human explicitly provided an assignee username when describing the issue, use that username.
- If no user is specified, you MUST fetch the available assignees and present them using the `AskUserQuestion` tool as a selector so the user can pick without typing. Delegate the fetch to a cheaper model (e.g., Claude Haiku) via the GitHub API: `gh api repos/{owner}/{repo}/assignees --jq '.[].login'` (substituting the repo derived above). Then call `AskUserQuestion` with each username as an option (label: the username, description: their role if known, otherwise leave blank). Do not proceed until the user has made a selection.

### Step 4: Format the Issue Body
DO NOT SKIP THIS UNTIL IS DONE.
The issue body MUST BE clear and actionable, formatted in Markdown, and contain the following sections at a minimum:

1. **Problem Description**: A clear and concise explanation of the problem or feature requirement. Include any relevant context. If the issue is about a bug, include steps to reproduce it.
2. **Definition of Done (Checklist)**: A bulleted checklist (`- [ ]`) describing exactly what needs to be implemented to consider the issue complete.
3. **Execution Instructions**:
   - Add a reminder to strictly follow red-green Test-Driven Development (TDD) principles for issues involving code logic or features.

### Step 5: Create the Issue
DO NOT SKIP THIS UNTIL IS DONE.
Once all information is gathered and the assignee is confirmed by the user write the issue title and body, then present to the user for confirmation.

If the user confirms, delegate the issue creation task to a cheaper, faster model to create the issue in the repository derived in Step 2.

### Step 6: Notify the User
DO NOT SKIP THIS UNTIL IS DONE.
Notify the human when the issue has been successfully created and share the clickable GitHub URL of the new issue in your response.
