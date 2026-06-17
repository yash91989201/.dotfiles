---
description: Analyze git changes, group by logical intent, present commit plan, then use git-commit skill after approval
argument-hint: "[files | patterns | --staged]"
---
# Smart Commit

Inspect → group → plan → per-group review → commit → push.

## Step 1 — Inspect

```bash
git status --porcelain
git diff --stat && git diff
git diff --staged --stat && git diff --staged
```

Scope by `$ARGUMENTS` (file paths, patterns, or `--staged`). Default: all changes. Read untracked files before grouping.

## Step 2 — Group

One intent per commit: `feat` / `fix` / `refactor` / `docs` / `test` / `config` / `chore`.

Exclude: `.env*`, credentials, keys, tokens, local config, generated artifacts.

## Step 3 — Plan

```
Changes: <N> files | Groups: <N>

G1: <type>(<scope>) — <description>
G2: ...

Skipped: <path> — <reason>
```

## Step 4 — Per-Group Review

For each group `i` of `N`, call `ask_user_question` **once** with commit card preview.

**Commit card** (pass as `preview`):

```markdown
### <type>(<scope>): <short title>

<1-3 sentence description, imperative mood>

**Files (<count>):**
- `<A/M/D/R>` `<filepath>` (+<lines>/-<lines>)
```

`A`=added, `M`=modified, `D`=deleted, `R`=renamed. `+/-` from `git diff --stat`.

```js
ask_user_question({
  questions: [{
    question: `[${i}/${N}] Commit: <intent>?`,
    header: `${type}(${scope})`,  // ≤16 chars
    options: [
      {
        label: "Commit this group",
        description: `${M} file(s)`,
        preview: commitCard
      },
      {
        label: "Skip this group",
        description: "Leave uncommitted"
      },
      {
        label: "Cancel all",
        description: "Nothing committed"
      }
    ]
  }]
})
```

| Choice | Action |
|---|---|
| Commit this group | → commit queue |
| Skip this group | → skip list |
| Cancel all | → abort |

If `N=1`, ask in prose (y/n). If `N>4`, batch in groups of 4.

## Step 5 — Execute

For each queued group (in order):
1. Stage that group's files
2. Commit via `git-commit` skill
3. Verify commit hash before next group

On failure → ask user: "Retry" / "Skip this group" / "Stop here".

## Step 6 — Push

Show all commit titles as multi-select list. User checks which to push.

```js
ask_user_question({
  questions: [{
    question: `Push ${commitCount} commit(s) to origin/${branch}?`,
    header: "Push",
    multiSelect: true,
    options: commits.map(c => ({
      label: `${c.hash.slice(0,7)} ${c.message}`,
      description: `push to origin/${branch}`
    }))
  }]
})
```

If no upstream, ask "Set upstream and push" / "Skip push" first.

## Final Report

```
Done.
Commits: <hash> <message>  (one per line)
Pushed: yes/no
Remote: <remote>/<branch>
Skipped: <path> — <reason>
Errors: none, or details
```
