---
description: Analyze git changes, group by logical intent, present commit plan, then use git-commit skill after approval
argument-hint: "[files | patterns | --staged]"
---
# Smart Commit

Inspect → group → plan → per-group review → commit → push.
Use `git-commit` skill for type/scope inference, staging, and commit formatting.

## Step 1 — Inspect

```bash
git status --porcelain
git diff --stat && git diff
git diff --staged --stat && git diff --staged
```

Scope by `$ARGUMENTS` (file paths, patterns, or `--staged`). Default: all changes. Read untracked files before grouping.

## Step 2 — Group

One intent per commit: `feat` / `fix` / `refactor` / `docs` / `test` / `config` / `chore`. Separate risky from cleanup. Never mix.

Exclude from all groups: `.env*`, credentials, keys, tokens, local config, generated artifacts.

## Step 3 — Plan

```
Changes: <N> files | Groups: <N>

G1: <type>(<scope>) — <description>
G2: ...

Skipped: <path> — <reason>
```

## Step 4 — Per-Group Review

For each group `i` of `N`, call `ask_user_question` **once**. The `preview` field shows the **commit card** — full file list, line counts, and description.

**Commit card** (pass as `preview`):

```markdown
### <type>(<scope>): <short title>

<1-3 sentence description, imperative mood>

**Files (<count>):**
- `<A/M/D/R>` `<filepath>` (+<lines>/-<lines>)
```

`A`=added, `M`=modified, `D`=deleted, `R`=renamed. `+/-` from `git diff --stat`. List all files, no truncation.

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
| Cancel all | → abort, nothing committed |

Repeat for all `N` groups. If `N=1`, ask in prose (y/n) — tool requires ≥2 options. If `N>4`, batch in groups of 4.

## Step 5 — Execute

For each queued group (in order):
1. Stage only that group's files
2. Commit via `git-commit` skill
3. Verify commit hash before next group

On failure → `ask_user_question` with: "Retry" / "Skip this group" / "Stop here". Never auto-continue.

## Step 6 — Push

If any commits made, show all commit titles as a multi-select list. User checks which to push, unchecked stay local.

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

Push only checked commits. If none checked, skip push. If no upstream, ask "Set upstream and push" / "Skip push" first. Never force push.

## Final Report

```
Done.
Commits: <hash> <message>  (one per line)
Pushed: yes/no
Remote: <remote>/<branch>
Skipped: <path> — <reason>
Errors: none, or details
```
