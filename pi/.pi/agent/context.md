# fixer vs worker — Pi subagent config comparison

## Files Retrieved

1. `/home/yash/.pi/agent/agents/fixer.md` (user-defined, 95 lines) — custom implementation agent
2. `/home/yash/.dotfiles/pi/.pi/agent/npm/node_modules/pi-subagents/agents/worker.md` (builtin, 71 lines) — package-shipped default
3. `/home/yash/.pi/agent/settings.json` lines 40-72 — `subagents.agentOverrides` shows `worker` override but **no** `fixer` override

## Key Code

### Source

- **fixer**: USER only. No `fixer.md` in `pi-subagents/agents/` builtin set. Custom.
- **worker**: BUILTIN (`pi-subagents@latest`), partially overridden in `settings.json`.

### Frontmatter side-by-side

| field | fixer | worker |
|---|---|---|
| `name` | fixer | worker |
| `description` | Fast focused implementation, fire-and-forget after scout/researcher, no escalation | Implementation for normal tasks + approved oracle handoffs |
| `defaultContext` | `fresh` | `fork` |
| `thinking` | `low` | `high` |
| `model` | `fireworks/accounts/fireworks/models/minimax-m3` (in agent file) | not in agent file; **override** sets `fireworks/.../minimax-m3` (effective same) |
| `tools` | `read, grep, find, ls, bash, edit, write, morph_fastapply, contact_supervisor` | not in agent file; **override** sets same list (effective same) |
| `systemPromptMode` | `replace` | `replace` |
| `inheritProjectContext` | `true` | `true` |
| `inheritSkills` | `false` | `false` |
| `defaultReads` | `context.md, plan.md` | `context.md, plan.md` |
| `defaultProgress` | `false` | `true` |

### Role / system prompt

- **fixer**: "fast, focused implementation specialist". Receives complete context + spec, executes, no research, no delegation, no decisions. Smallest correct change. Strict output format (`<summary>/<changes>/<verification>`).
- **worker**: "single writer thread". Validates task against actual code, narrow coherent edits, may escalate via `contact_supervisor(reason: "need_decision")` for unapproved decisions. Output shape: "Implemented X / Changed files / Validation / Risks / Next step".

### Tools / permissions

- Both end up with identical effective toolsets after override.
- **fixer** body contradicts itself: "NO delegation... No `contact_supervisor`" yet `contact_supervisor` is listed in `tools:` and "Only ask the orchestrator for missing inputs" mentions the channel.
- **worker** body actively uses `contact_supervisor` with `need_decision` / `progress_update` reasons; falls back to `intercom` only when unavailable.

### Acceptance / defaults

- No formal acceptance contract on either. Both rely on parent acceptance via return summary.
- **fixer** specifies output XML structure as contract.
- **worker** specifies prose summary shape; allows escalation as alternative to silent decision.

### Timeout / model config

- No `timeout` field on either.
- Effective model for both: `fireworks/accounts/fireworks/models/minimax-m3`.
- Thinking: fixer `low` (cheap, fast); worker `high` (deeper reasoning, slower + more tokens).

## Architecture

`pi-subagents` package ships 8 builtins (context-builder, delegate, oracle, planner, researcher, reviewer, scout, worker). User `~/.pi/agent/agents/` shadows builtins (currently overrides researcher, scout, plus adds 10 custom including fixer). `settings.json.subagents.agentOverrides` patches specific fields on builtins per-user.

## Start Here

Open `/home/yash/.pi/agent/agents/fixer.md` first — fully user-owned, has the in-body `contact_supervisor` contradiction that should be resolved. Then `worker.md` and the `worker` block in `settings.json` for effective behavior.

## Practical behavior differences

1. **Context inheritance**: `fresh` = no parent context (fixer relies entirely on supplied `context.md`/`plan.md`); `fork` = inherits parent context (worker can build on prior turns).
2. **Reasoning depth**: `low` thinking = cheap, terse, less self-check (fixer); `high` thinking = more validation, more tokens (worker).
3. **Escalation posture**: fixer forbids escalation in prose; worker mandates `contact_supervisor` for unapproved decisions.
4. **Progress tracking**: `defaultProgress: false` (fixer) vs `true` (worker) — worker is expected to maintain `progress.md`.
5. **Use case**: fixer = well-specified post-research, single-shot edits. worker = approved plans, oracle handoffs, multi-step with live coordination.

## Notable issue (severity: medium)

`fixer.md` Constraints block says "NO delegation... No `contact_supervisor`" but `tools:` frontmatter and later prose ("Only ask the orchestrator for missing inputs") both reference it. Effective runtime will allow `contact_supervisor`; the prose constraint is unenforceable. Recommend either removing `contact_supervisor` from tools or rewording constraint to "minimize, prefer local resolution".
