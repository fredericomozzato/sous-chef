---
Guide for how to proceed when pull requests require screenshots to display UI visual changes
---

When creating a PR that requires screenshots, follow this process:

- Use the playwright MCP
- Save all screenshots to the draft folder
- Use leading numbers for ordering: `001_name.png`, `002_name.png`, etc.
- Use lowercase with underscores for names
- Capture all relevant states: empty state, filled state, error state, mobile view
- Screenshot both light and dark mode to ensure both states were correctly updated
- Prioritize mobile width unless instructed otherwise

### 1. Create Draft Folder (Before PR Creation)
Since the PR number isn't known yet, create a temporary draft folder:
- Format: `tmp/pr/draft_{brief_title}/`
- Example: `tmp/pr/draft_add_insights_panel/`
- Use lowercase with underscores for the title
- Keep the title brief (3-5 words max)

### 2. Screenshot Naming Convention
- Use leading numbers (001, 002, 003, etc.) for ordering
- Add a brief descriptive name after the number
- Use lowercase with underscores
- Examples:
  - `001_empty_state_light.png`
  - `002_form_filled_dark.png`
  - `003_mobile_view.png`
  - `004_error_validation.png`

### 3. PR Description Format
- Place image placeholders exactly where the screenshot should appear
- Use the format: `<!-- IMAGE: filename.png -->`
- **Only include the filename, NOT the folder path**
- Add context text before each placeholder

Example:

```markdown
The insights panel appears empty when no products are added:

<!-- IMAGE: 001_empty_insights_panel.png -->

After filling in two products, the panel displays relevant insights:

<!-- IMAGE: 002_insights_with_two_products.png -->

The panel adapts when comparing three or more products:

<!-- IMAGE: 003_insights_with_three_products.png -->

On mobile devices (375px width), the layout remains readable:

<!-- IMAGE: 004_mobile_view.png -->
```


### 4. Parallel execution

We need to save tokens and preserve context. If possible delegate the screenshot operations to a parallel agent. If you have access to cheaper models do this.

Claude should use Haiku.

Gemini should use gemini-flash.
