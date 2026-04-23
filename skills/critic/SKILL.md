---
name: chef:critic
description: Use before creating a pull request to run the RubyCritic code quality check. Covers running the check, interpreting results, handling score changes, and producing the score table for the PR description.
---

# Critic Skill

This skill defines the mandatory process for running the RubyCritic code quality check before opening a pull request.

## How It Works

`check-rubycritic.sh` runs RubyCritic against the `app/` directory inside the Docker web container and compares the result against the minimum acceptable score stored in `.rubycritic_minimum_score` at the project root.

The script always prints:
```
Current score : 92.38
Minimum score : 93.11
```

And exits with one of three outcomes:
- **PASS** — score maintained (current == minimum)
- **IMPROVED** — score increased (current > minimum); `.rubycritic_minimum_score` is automatically updated by the script
- **FAIL** — score decreased (current < minimum); script exits with code 1

## Step-by-Step Workflow

### Step 1: Run the Check

```bash
check-rubycritic.sh
```

Capture the full output — you will need the current score, minimum score, and outcome for the PR description.

### Step 2: Handle the Result

#### PASS — Score maintained

Continue to the PR without interruption. Delete the "Score Trade-off" section from the PR description template.

#### IMPROVED — Score increased

The script automatically writes the new score to `.rubycritic_minimum_score`. You MUST commit this file together with the branch changes before creating the PR:

```bash
git add .rubycritic_minimum_score
git commit -m "Update RubyCritic minimum score to {current_score}"
```

Delete the "Score Trade-off" section from the PR description template.

#### FAIL — Score decreased

This is a **soft block** — do NOT proceed silently.

1. Report the exact drop to the user:
   > "Score dropped from {minimum_score} to {current_score}, a decrease of {diff} points."
2. Identify which files likely contributed (visible in the RubyCritic output).
3. Ask the user how to proceed:
   - Fix the quality issues now and re-run the check, OR
   - Merge anyway with a written justification

Do NOT proceed until the user makes a conscious decision. If they choose to merge, include the "Score Trade-off" section in the PR description.

### Step 3: Prepend the Score Table to the PR Description

Read `sous-chef/CHECKPOINT` to get `MILESTONE` and `SLICE`. The description file is at:

```
tmp/screenshots/pr/{MILESTONE}/{SLICE}/description.md
```

Prepend the following block to the top of that file (above all existing content):

```markdown
| Branch Score | Minimum Score | Status |
| --- | --- | --- |
| {current_score} | {minimum_score} | PASS |
```

Use `PASS` when current score >= minimum score, `FAIL` otherwise.

If status is `FAIL`, also prepend the warning block immediately after the table:

```markdown
> [!WARNING]
> Score dropped. If you decide to merge, remember to manually update `.rubycritic_minimum_score` to the new score before merging.

## Score Trade-off

[Explain why the score dropped and why merging is still acceptable. Describe the smells introduced, which files are affected, and whether there is a plan to address them in a follow-up.]
```

If status is `PASS`, do not add the warning block.

---

## Summary Checklist

- [ ] `check-rubycritic.sh` run and full output captured
- [ ] Current score and minimum score noted
- [ ] If IMPROVED: `.rubycritic_minimum_score` committed with the branch changes
- [ ] If FAIL: user informed of exact score drop and conscious decision obtained
- [ ] Score table added to PR description with correct PASS/FAIL status
- [ ] "Score Trade-off" section included (FAIL) or deleted (PASS)
