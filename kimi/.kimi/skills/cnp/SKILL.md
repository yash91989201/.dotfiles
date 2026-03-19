---
name: cnp
description: Review repository changes, group them by intent, create conventional commits, and push.
---

## Workflow

### 1. Check Repository State

- Run `git_status`.
- If there are no modified, staged, or untracked files, output: `No changes to commit.`

### 2. Review Changes

- Use `git_diff_unstaged` and `git_diff_staged` to understand the changes.

### 3. Group by Intent

Organize files into logical change groups such as:

| Type | Purpose |
|------|---------|
| `feat` | New feature |
| `fix` | Bug fix |
| `refactor` | Code restructuring |
| `docs` | Documentation |
| `style` | Formatting/style |
| `test` | Tests |
| `chore` | Maintenance |
| `perf` | Performance |

Each group should represent one clear purpose.

### 4. Stage Files

Stage files for each group using `git_add`.

### 5. Commit

Create a conventional commit for each group.

**Header format:**

```
type(scope): subject
```

**Guidelines:**

- `scope` is optional and short
- `subject` is imperative and ≤ 80 characters

Include a description in bullet points, for small changes keep it upto 5 bullet points , but for big changes keep it upto 10 bullet points

### 6. Push

After all commits are created, push the branch.

---

## Output

Keep output minimal. If an error occurs, report the step and the error briefly.
