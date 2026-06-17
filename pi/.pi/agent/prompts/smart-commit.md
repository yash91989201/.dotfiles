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

Apply `$ARGUMENTS` scope where relevant. Read untracked file contents before grouping.

## Step 2 — Detect Unsafe Files

Exclude from all groups: `.env*`, credentials, private keys, tokens, local config, generated artifacts. List as skipped in the plan.

## Step 3 — Group by Intent

One logical intent per commit. Separate features / fixes / refactors / docs / tests / config / chores. Don't mix risky changes with cleanup. Use `git-commit` skill to infer type, scope, and message per group.

## Step 4 — Output Plan

Post the full plan in your response before anything else happens:

```
Commit plan
Changes: <N> files  |  Groups: <N>

Group 1: <intent>
Files: <path> (<status>), ...
Commit: <conventional message>
Why: <one line>

Skipped: <path> — <reason>
```

## Step 5 — Approval (MUST use `ask_user_question` — never plain text)

Call `ask_user_question` right after the plan, with these four choices: commit and push, commit only, modify plan, cancel. Do not ask in prose, list options as markdown, or proceed without this call. End your turn immediately after calling it.

## Step 6 — Handle Response

| Choice | Action |
|---|---|
| Commit and push | Step 7, `push=true` |
| Commit only | Step 7, `push=false` |
| Modify plan | Ask what to change in prose → regenerate plan (Step 4) → call `ask_user_question` again (Step 5). Never resume without a fresh approval call. |
| Cancel | Stop. Report cancelled. No staging/commits. |

## Step 7 — Execute

Per group: stage only that group's files → commit via `git-commit` skill → verify before next group.

On failure: stop, show error, call `ask_user_question` with choices retry / skip this group / stop. Never auto-continue or ask in free text.

## Step 8 — Push

Only if `push=true`. If no upstream, call `ask_user_question` with choices set upstream and push / skip push, before:

```bash
git push -u origin HEAD
```

Never force push.

## Final Report

```
Done.
Commits: <hash> <message> (one per line)
Pushed: yes/no
Remote: <remote>/<branch>
Skipped: <path> — <reason>
Errors: <none or details>
```
