---
description: Analyze git changes, group by logical intent, present commit plan, then use git-commit skill after approval
argument-hint: "[files | patterns | --staged]"
---

# Smart Commit

Workflow: inspect → group → plan → approve → commit → push.
Use the `git-commit` skill for conventional commit formatting, type/scope inference, and staging.

## Inputs

`$ARGUMENTS`: file paths, patterns, or `--staged` to limit scope. Default: all changes.

## Step 1 — Inspect

```bash
git status --porcelain
git diff --stat && git diff
git diff --staged --stat && git diff --staged
```

Apply `$ARGUMENTS` scope where relevant. For untracked files, read contents before grouping.

## Step 2 — Detect Unsafe Files

Flag and exclude from all groups: `.env*`, credential files, private keys, tokens, local config, generated artifacts. List them in the plan as skipped.

## Step 3 — Group by Intent

One logical intent per commit. Keep related files together; split unrelated ones.
Separate: features / fixes / refactors / docs / tests / config / chores.
Don't mix risky changes with cleanup.
Use `git-commit` skill to infer type, scope, and message per group.

## Step 4 — Output Plan

Write the full plan into your response. This is not an internal step — the user must see it before anything else happens.

```
Commit plan
Changes: <N> files  |  Groups: <N>

Group 1: <intent>
Files: <path> (<status>), ...
Commit: <conventional message>
Why: <one line>

Group 2: ...

Skipped: <path> — <reason>
```

**End your response here. Do not ask for approval in this message.**

## Step 4b — Request Approval

Send this as your next message:

```
Choose:
1. Approve all + push
2. Approve, no push
3. Modify plan
4. Cancel
```

**Wait for the user's reply before doing anything.**

## Step 5 — Handle Response

| Choice           | Action                                      |
|------------------|---------------------------------------------|
| Approve + push   | Commit per plan → push                      |
| Approve, no push | Commit per plan                             |
| Modify           | Ask what to change → re-present plan → wait |
| Cancel           | Stop, report cancelled                      |

## Step 6 — Execute

Per group:

1. Stage only that group's files
2. Use `git-commit` skill to commit
3. Verify success before next group

On failure: stop, show error, ask how to proceed. Do not auto-continue.

## Step 7 — Push

Only if approved. If no upstream, ask before running:

```bash
git push -u origin HEAD
```

Do not force push.

## Final Report

```
Done.
Commits: <hash> <message> (one per line)
Pushed: yes/no
Remote: <remote>/<branch>
Skipped: <path> — <reason>
Errors: <none or details>
```
