```markdown
Closes #[issue_number]
<!-- If no issue exists, remove the line entirely -->

| Branch Score | Minimum Score | Status |
| --- | --- | --- |
| [rubycritic_score] | [minimum_score] | [PASS or FAIL] |
<!-- Run `make rubycritic` to get both values. The output shows "Current score" and "Minimum score".
     Use PASS if current score >= minimum score, FAIL otherwise.
     If status is FAIL, include the warning block below. If status is PASS, delete it. -->

> [!WARNING]
> Score dropped. If you decide to merge, remember to manually update `.rubycritic_minimum_score` to the new score before merging.

## Score Trade-off
<!-- MANDATORY if status is FAIL. Delete this section if status is PASS. -->
[Explain why the score dropped and why merging is still acceptable. Describe the smells introduced,
which files are affected, and whether there is a plan to address them in a follow-up branch.]

# Motivation

[Explain what problem this PR solves and why it matters. Focus on user impact
or business value, not implementation details.]

# Proposed Solution

[Explain how the solution was implemented at a high level.]

**UI Changes:**
<!-- Delete this section if there are no UI changes -->
<!-- Screenshot placeholders: use <!-- IMAGE: filename.png --> format -->
[Add screenshots or screen recordings showing the changes]

## Testing

<!-- Add all the specs that were created or modified in the branch -->
```sh
make test \
  spec/path/to/first_spec.rb \
  spec/path/to/second_spec.rb
```


**Manual Testing Steps:**
<!-- Delete this subsection if no manual testing is needed -->
1. Navigate to `/path/to/page`
2. Fill the form with: [specific values]
3. Click [specific button]
4. Expected result: [what should happen]

## Observations

<!-- Optional: trade-offs, decisions, or anything reviewers should know -->
<!-- Delete this section if there are no special observations -->

## Pending

<!-- Optional: list anything from the issue NOT implemented in this PR -->
<!-- Delete this section if everything was implemented -->
```
