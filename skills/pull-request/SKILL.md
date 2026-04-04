---
name: chef:create-pull-request
description: Use this skill whenever you need to create a pull request OR update an existing PR description. Covers the full workflow from preparing the description to notifying the user after creation. Also applies when asked to update, rewrite, or add content to a PR description.
---

# Pull Request Creation Skill

This skill defines the mandatory process for creating pull requests in this repository.
All agents (Claude, Gemini, GPT) MUST follow this process exactly.

## Updating an Existing PR Description

If you are updating (not creating) a PR description, the same rules apply:
- Run `make rubycritic` and `bundle exec bundler-audit check --update` (in the web container) and include the score table at the top of the description
- Follow the pr-template structure for all sections
- Use the GitHub MCP (`mcp__github__update_pull_request`) to apply the update
- Do NOT skip the score table just because the PR already exists

## CRITICAL Rules

- NEVER mention any AI, agent, or tool name in the PR body (no "Claude Code", "Gemini", "Antigravity", "Cursor", etc.)
- Write from a human developer perspective at all times
- Screenshots are MANDATORY for any UI changes
- Link the related issue if one exists with closing keywords (e.g. "Close #123")
- ALWAYS wait for explicit user approval before creating the PR
- NEVER add agent metadata or tooling references anywhere in the PR
- Always read the Git log to understand exactly what was implemented in the branch so you can correctly describe everything

## Step-by-Step Workflow

### Step 0: Pre-PR Quality Checks

Before doing anything else, run both quality checks:

#### 0a. Bundler Audit

```bash
docker compose exec web bundle exec bundler-audit check --update
```

**If vulnerabilities are found:**
- This is a **hard block** — do NOT proceed with the PR
- Report every CVE found to the user with the gem name, version, and advisory URL
- The user must resolve the vulnerabilities (bump the affected gems) before the PR can be created

**If no vulnerabilities are found:**
- Continue to 0b without interruption

#### 0b. RubyCritic Score Check

Follow the `/chef:critic` skill. It covers running the check, interpreting results, handling score changes, committing `.rubycritic_minimum_score` if improved, and producing the score table for the PR description.

### Step 1: Prepare the Draft Folder

Before writing the description, create a temporary draft folder since the PR number is not known yet.

Format: `tmp/pr/draft_{brief_title}/`

Rules for `brief_title`:
- Lowercase with underscores
- 3-5 words maximum
- Describes the feature or fix

Example:
```bash
mkdir -p tmp/pr/draft_add_formatted_name/
```

### Step 2: Capture Screenshots (if UI changed)

If the PR includes any UI changes, screenshots are MANDATORY. Follow the [screenshots-workflow](./screenshot-workflow.md) guide.

### Step 3: Write the PR Description

Write the full PR description following the template below.
Save it to: `tmp/pr/draft_{brief_title}/description.md`

Follow the [template](./pr-template.md) when writing the description.

### Step 4: Show Description and Wait for Approval

After writing the description to the file, display the full content to the user and explicitly ask for approval before proceeding.

Example message to user:
```
I've prepared the PR description and saved it to tmp/pr/draft_{brief_title}/description.md

Here's the full description:

[Show full PR description content here]

Would you like me to create the PR with this description, or would you like any changes first?
```

**Do NOT proceed until the user explicitly confirms.**

### Step 5: Push the Branch

Before creating the PR, ensure the branch is pushed to the remote:

```bash
git push -u origin {branch-name}
```

If the push fails, resolve the issue before proceeding. Do NOT attempt to create the PR until the branch exists on the remote — the MCP call will fail.

### Step 6: Create the PR

Only after user approval and the branch is pushed, create the PR.

**Tool priority (MANDATORY — follow this order):**
1. **GitHub MCP** (`mcp__github__create_pull_request`) — always use this first
2. **`gh` CLI** — only if the MCP is unavailable or returns an error
3. **GitHub REST API via `curl`** — last resort only

If none of the above tools are available, stop and prompt the user to configure the GitHub MCP or install the `gh` CLI. Offer setup instructions.

PR Title Rules:
- Type MUST be uppercase, surrounded by square brackets
- Allowed types: `[FEAT]`, `[FIX]`, `[CHORE]`, `[DOCS]`, `[REFACTOR]`, `[TEST]`, `[AGENTS]`
- Use `[AGENTS]` for any work related to agent configuration, skills, slash commands, or AI workflow tooling
- After the type, write a concise description in sentence case (capitalize only the first word)
- No colon, no dash — just the bracketed type followed by a space and the description

Good examples:
```
[FEAT] Add formatted_name method to Whey model
[FIX] Solve calculator bug when serving size is zero
[CHORE] Create PR creation skill
[AGENTS] Add progress skill with save and resume slash commands
[AGENTS] Update issue-solver skill to delegate to Haiku subagent
```

Bad examples (FORBIDDEN):
```
feat: solve bug
CHORE - improve docker
Add new whey model
[feat] lowercase type
```

### Step 7: Rename the Draft Folder

After the PR is created, extract the PR number from the response and rename the folder:

```bash
mv tmp/pr/draft_{brief_title} tmp/pr/{PR_NUMBER}_{brief_title}
```

Example:
```bash
mv tmp/pr/draft_add_formatted_name tmp/pr/115_add_formatted_name
```

### Step 8: Open the Screenshots Folder (if screenshots exist)

If the PR includes screenshots, open the renamed folder in the system file explorer so the user can immediately drag and drop images into the PR.

Detect the OS and use the correct command:
- **macOS**: `open tmp/pr/{PR_NUMBER}_{brief_title}/`
- **Linux**: `xdg-open tmp/pr/{PR_NUMBER}_{brief_title}/`

To detect the OS, run `uname -s`: output `Darwin` means macOS, `Linux` means Linux.

Skip this step if there are no screenshots.

### Step 9: Notify the User

After renaming, tell the user:
- The PR number and clickable URL
- Where the files are saved
- Next steps for uploading screenshots (if applicable)

Example message:
```
PR #115 has been created at https://github.com/user/repo/pull/115

Files saved to tmp/pr/115_add_formatted_name/:
- description.md

Next steps:
- Review the PR on GitHub
- If there are image placeholders, upload screenshots and replace each
  <!-- IMAGE: filename.png --> comment with the uploaded image
```

---

## Summary Checklist

Before closing this skill, verify:
- [ ] Bundler audit run (`bundler-audit check --update` in web container) — no vulnerabilities found (hard block if any)
- [ ] `/chef:critic` skill completed — score table produced, `.rubycritic_minimum_score` committed if improved
- [ ] PR description includes the score table with PASS or FAIL status
- [ ] "Score Trade-off" section included if score is FAIL, deleted if PASS
- [ ] Draft folder created at `tmp/pr/draft_{brief_title}/`
- [ ] Screenshots captured (if UI changed)
- [ ] Description written following the template
- [ ] Description saved to `tmp/pr/draft_{brief_title}/description.md`
- [ ] Full description shown to user and approval received
- [ ] Branch pushed to remote (`git push -u origin {branch-name}`)
- [ ] PR created using GitHub MCP (fallback to `gh` CLI only if MCP unavailable)
- [ ] Draft folder renamed to `tmp/pr/{PR_NUMBER}_{brief_title}/`
- [ ] Screenshots folder opened in file explorer (macOS: `open`, Linux: `xdg-open`) — skip if no screenshots
- [ ] User notified with PR number, URL, and next steps
- [ ] No AI/agent names anywhere in the PR body
