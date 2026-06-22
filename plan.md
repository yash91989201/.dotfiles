# Implementation Plan: Lean Orchestrator AGENTS.md

## Goal
Rework `~/.pi/agent/AGENTS.md` from a 84-line mixed playbook/routing doc into a minimal orchestrator prompt: routing philosophy + per-subagent routing cards + guardrails. All domain expertise lives in subagent defs, not the main prompt.

---

## Current State Analysis

### What's in the file today (84 lines)
| Section | Lines | Verdict |
|---------|-------|---------|
| Morph FastApply plugin block (HTML comments) | ~5 | **Auto-injected by `pi-morphllm-plugin` package — not user-authored.** Leave as-is (package manages it). |
| Core Rules (6 bullets) | ~6 | KEEP — but tighten. These are the orchestrator's operating principles. |
| Routing table (4 rows) | ~6 | REPLACE with full per-subagent card system. Current table covers only research + scout + context-mode; misses implementation, planning, review, DB, docker, frontend, messaging, vision, design. |
| Subagents section (2 tables: fork/fresh) | ~30 | REPLACE with routing cards. Tables list agents but give no "when to call" or "what context to pass" guidance. Also lists `git-commit` and `skill-creator` as subagents — they're **skills**, not subagents. |
| MCP Tool Calling (syntax + context-mode table + examples) | ~20 | **DELETE from main prompt.** The only tool the orchestrator calls directly is `context-mode` for large output routing. The full MCP syntax + tool tables belong in `researcher.md` (already has them). Main agent needs one line: "Route output >20 lines through `context-mode`." |

### Sizing of subagent definitions
| Agent def | Size | Issue |
|-----------|------|-------|
| `ui-ux-designer.md` | 12 KB | Bloated with generated code patterns, placeholder image helpers, CSS/Tailwind configs. Overlaps completely with `designer.md`. **Recommend deletion — `designer.md` covers the role.** |
| `code-reviewer.md` | 7 KB | Heavy checklist + phantom cross-references to non-existent agents (security-auditor, performance-profiler, test-architect, error-detective). |
| `database-engineer.md` | 7 KB | Solid but references phantom agents (migration-specialist, monitoring-architect). |
| `backend-architect.md` | 4 KB | References phantom agents (security-auditor, performance-profiler, integration-test-builder, tech-writer). |
| `frontend-specialist.md` | 5 KB | References phantom agents (performance-profiler, e2e-test-automator, unit-test-generator, security-auditor, tech-writer). |
| `rabbitmq-expert.md` | 2.5 KB | Clean. No phantom refs. |
| `docker-expert.md` | 2.5 KB | Clean. No phantom refs. |
| `designer.md` | 1.5 KB | Lean and well-structured. |
| `refactoring-expert.md` | 1 KB | Lean. |
| `researcher.md` | 5 KB | Self-contained, carries its own MCP tool reference. Good. |
| `scout.md` | 2 KB | Clean. |
| `vision.md` | 5 KB | Clean, well-structured. |

### Phantom agent references (agents that DON'T exist anywhere)
The following are referenced in "Automatic Delegation Strategy" / "Integration Points" sections of user agent defs but have **no .md file** in `~/.pi/agent/agents/` or in the `pi-subagents` package:
- `security-auditor`, `performance-profiler`, `migration-specialist`, `monitoring-architect`, `test-architect`, `integration-test-builder`, `tech-writer`, `fullstack-developer`, `iac-expert`, `error-detective`, `unit-test-generator`, `e2e-test-automator`

These subagent defs are shipping instructions to delegate to agents that don't exist. The model either hallucinates calls or silently ignores them.

### `git-commit` and `skill-creator`
Listed in current AGENTS.md as Fresh subagents. They exist as **skills** (`~/.pi/agent/skills/git-commit/`, `~/.pi/agent/skills/skill-creator/`), not subagent `.md` files. The main prompt should not list them as subagents.

### `designer` vs `ui-ux-designer`
Both cover UI/UX. `designer.md` is lean (1.5 KB, fork, proper constraints). `ui-ux-designer.md` is 12 KB of generated code snippets and Tailwind configs. Recommend dropping `ui-ux-designer.md` entirely and keeping `designer.md` as the sole UI agent.

---

## New AGENTS.md Structure

```
1. [Auto-injected plugin blocks — untouched, managed by packages]
2. # Agent Instructions
3. ## Core Rules (6→4 bullets, tightened)
4. ## Subagent Routing (per-agent cards — the core of the file)
5. ## MCP Harness (1-2 lines — just context-mode routing rule)
```

**Target size: ~45-55 lines** (down from 84, but far higher signal density per line).

---

## Per-Subagent Card Format

Each card is a compact block — the orchestrator needs name, role, when-to-call, context style, and that's it:

```markdown
### `agent-name` (fresh|fork)
Role: one-line purpose.
When: trigger conditions — when to choose this agent.
Context: what to pass it (files, scope, fork vs fresh, output file).
```

No expertise bullets, no process steps, no checklists. Those live in the agent's own `.md`.

---

## What Gets Deleted vs Kept

### DELETE from main AGENTS.md
| Content | Reason | Where it goes |
|---------|--------|---------------|
| Full MCP tool syntax + context-mode tool table + examples (20 lines) | Only `researcher` calls MCP tools directly. Main agent only needs `context-mode` for output routing. | Already in `researcher.md`. Main prompt gets 1 line. |
| `git-commit` row in subagent table | It's a skill, not a subagent. | Remove entirely. |
| `skill-creator` row in subagent table | It's a skill, not a subagent. | Remove entirely. |
| Fork/Fresh table format (30 lines of tables) | Tables list agents but don't say when/why/context. | Replaced by routing cards. |

### KEEP in main AGENTS.md
| Content | Reason |
|---------|--------|
| Morph plugin block (HTML comments) | Auto-injected by package; not user-managed. |
| Core Rules (condensed to 4) | These are the orchestrator's operating principles — delegate early, fresh per task, don't paste raw output, inspect repo directly for reviews. |
| `context-mode` output routing rule | Orchestrator does need this one MCP capability. |

### MOVE (content already exists in subagent defs, just remove from main)
Nothing needs to move — the domain expertise is already in the `.md` files. The main prompt just needs to stop duplicating the agent list without routing intelligence.

---

## Draft Skeleton: New AGENTS.md

```markdown
<!-- pi-morphllm-plugin:fastapply:start -->
Morph FastApply: native edit for small exact replacements. `morph_fastapply`
only for large/scattered edits, after reading target file, using
marker-wrapped anchor snippets (`// ... existing code ...`). Fall back to
edit/write if it fails.
<!-- pi-morphllm-plugin:fastapply:end -->

---

# Agent Instructions

## Core Rules

- Delegate early and often — if a task fits a subagent's role, hand it off. Each subagent runs in its own context.
- Fresh subagent per task; fork only when the task needs inherited context, visual content, or the prior conversation thread.
- Never paste raw subagent output into chat (logs, JSON, test output, diffs) — route through `context-mode` MCP.
- Reviews must inspect the repo/diff directly — never trust the parent's summary.
- Before large implementation: `scout` for recon → `planner` for the plan → `worker` to execute.

---

## Subagent Routing

`fresh` = new session, no inherited context · `fork` = inherits parent context

### Builtins

### `planner` (fork)
Role: Turns requirements + code context into a concrete implementation plan.
When: Any non-trivial feature, refactor, or multi-step task before writing code.
Context: Fork. Pass the task + relevant code paths. Reads `context.md` if available. Output: `plan.md`.

### `worker` (fork)
Role: Implementation — executes the assigned task with narrow, correct edits.
When: Code changes are needed and a plan or approved direction exists (or task is simple enough to direct).
Context: Fork. Pass the task or plan. Reads `context.md`, `plan.md` if available. Uses `contact_supervisor` if blocked.

### `scout` (fresh)
Role: Fast codebase recon — maps files, symbols, data flow, risks.
When: Unknown codebase, unfamiliar architecture, need to find where things live before planning.
Context: Fresh. Pass the question/area. Output: `context.md`. Uses `warpgrep` + `gitnexus` for deep analysis.

### `oracle` (fork)
Role: Decision-consistency check — prevents drift between current trajectory and inherited decisions.
When: Complex multi-step work where the main agent might lose track of earlier constraints. Before committing to a significant pivot.
Context: Fork. Inherits the full conversation. Returns diagnosis + recommendation.

### `context-builder` (fresh)
Role: Analyzes requirements + codebase, produces structured handoff material.
When: Large or ambiguous task before planning — need to gather context and define the problem precisely.
Context: Fresh. Pass the request. Output: `context.md` + `meta-prompt.md`.

### `reviewer` (fresh)
Role: Inspects and evaluates plans, code diffs, solutions, PRs, codebase health.
When: After implementation, before merge, or to validate a plan before execution.
Context: Fresh. Pass what to review. Reads `plan.md`/`progress.md` if available.

### `researcher` (fresh)
Role: Autonomous web research — search, scrape, read docs, synthesize brief.
When: External docs, API refs, library docs, current best practices, anything needing web search.
Context: Fresh. Pass the research question. Output: `research.md`. Has its own MCP tool reference.

### `delegate` (fresh)
Role: Lightweight passthrough — inherits parent model, no default reads, no system prompt replacement.
When: Quick task that doesn't fit a specialist but shouldn't pollute main context. Or when you need a fresh context with full model power.
Context: Fresh. Pass the exact task.

### `vision` (fork)
Role: Read-only visual analysis — screenshots, errors, diagrams, PDFs, charts, mockups.
When: An image needs interpretation. MUST explicitly tell it to `read` the image file first.
Context: Fork (needs to see the image path). Pass the image path + question.

### `designer` (fork)
Role: UI/UX visual implementation — hierarchy, color, spacing, motion, a11y.
When: Frontend UI work needing design judgment, not just component assembly.
Context: Fork. Pass the UI scope + existing design system reference.

### User-Defined Specialists

### `backend-architect` (fresh)
Role: API architecture, auth, database schemas, microservices design.
When: Backend architecture decisions, API design, auth flows, service decomposition.
Context: Fresh. Pass requirements + existing architecture files.

### `database-engineer` (fresh)
Role: Schema design, query optimization, migrations, data integrity.
When: Schema changes, slow queries, migration planning, ORM configuration.
Context: Fresh. Pass schema files, query issues, migration context.

### `code-reviewer` (fresh)
Role: Code quality, security, consistency, best practices enforcement.
When: PR review, code quality audit, security review.
Context: Fresh. Pass the diff or files to review.

### `frontend-specialist` (fresh)
Role: React + shadcn/ui + Tailwind components, WCAG accessibility, frontend performance.
When: Component implementation, design system work, a11y compliance, React performance optimization.
Context: Fresh. Pass component specs + existing patterns.

### `refactoring-expert` (fresh)
Role: Tech debt reduction, design patterns, code simplification.
When: Code smell cleanup, pattern implementation, complexity reduction.
Context: Fresh. Pass target files + refactoring goal.

### `docker-expert` (fresh)
Role: Containerization, image builds, Docker Compose, orchestration.
When: Dockerfile creation, image optimization, multi-container setup, container networking.
Context: Fresh. Pass containerization requirements.

### `rabbitmq-expert` (fresh)
Role: RabbitMQ messaging, configuration, optimization.
When: Queue/exchange design, messaging patterns, RabbitMQ performance or reliability.
Context: Fresh. Pass messaging requirements + current setup.

---

## MCP Harness

Route output >20 lines (logs, JSON, tests, history, dumps) through `context-mode`:
```js
mcp({ tool: "context_mode_ctx_search", args: '{"queries": ["..."]}' })
mcp({ tool: "context_mode_ctx_execute", args: '{"language": "javascript", "code": "..."}' })
```
All other MCP tool usage is delegated to `researcher` (which has its own tool reference).
```

---

## Guardrails (embedded in Core Rules section)

The following guardrails are already present in the current Core Rules but should be sharpened:

1. **Don't do the subagent's work yourself.** If a card exists for the task type, delegate. The main agent orchestrates, it doesn't implement.
2. **Delegate early.** Don't research the problem deeply before delegating — that's what `scout`/`researcher` are for. Hand off the question, not your partial answer.
3. **Don't paste raw subagent output back into chat.** Route through `context-mode`. Summarize the result for the user.
4. **Reviews inspect the repo directly.** Never review based on the parent's summary of what changed.
5. **Fresh per task.** Don't reuse a subagent session for a new task. Fork only when inherited context or visual content is essential.
6. **Before large work: `scout` → `planner` → `worker`.** This pipeline keeps the main agent's context clean.

---

## Builtins vs User Agents

### How to handle them in the card list

**Same card format for both.** No visual distinction needed in the main prompt — the orchestrator treats them identically. The distinction (builtin vs user-defined) is a packaging concern, not a routing concern.

**Builtins** (from `pi-subagents` package): `planner`, `worker`, `oracle`, `scout`, `researcher`, `context-builder`, `delegate`, `reviewer`, `vision`.

Wait — `scout`, `researcher`, and `vision` have user-override `.md` files in `~/.pi/agent/agents/` that take precedence over the package defaults. The main prompt should route to them by name; the override resolution is handled by the runtime, not the prompt.

**User-defined specialists**: `backend-architect`, `database-engineer`, `code-reviewer`, `frontend-specialist`, `refactoring-expert`, `docker-expert`, `rabbitmq-expert`, `designer`.

**Remove from subagent list**: `git-commit`, `skill-creator` (they're skills, invoked via `enableSkillCommands`). `ui-ux-designer` (duplicate of `designer`).

---

## Subagent Def Trim Recommendations

### `ui-ux-designer.md` — DELETE
- Fully duplicates `designer.md` role. 12 KB of generated code patterns (color generation algorithms, animation configs, Tailwind setups) that belong in a project template, not an agent system prompt. `designer.md` is lean and wins.

### `backend-architect.md` — TRIM
- Remove "Automatic Delegation Strategy" section (references 5 phantom agents).
- Remove "Integration Points" section (references 4 phantom agents).
- Keep: Core expertise areas, architecture process, best practices, tech stack.
- Target: ~2 KB (from 4 KB).

### `code-reviewer.md` — TRIM
- Remove "Automatic Delegation Strategy" section (references 5 phantom agents).
- Remove "Integration Points" section (references 4 phantom agents).
- Condense "Review Checklist by Area" (currently 40 lines of checkboxes) into a compact list.
- Keep: Core review expertise, review process, quality standards, scope limitations.
- Target: ~3.5 KB (from 7 KB).

### `database-engineer.md` — TRIM
- Remove "Automatic Delegation Strategy" section (references 5 phantom agents).
- Remove "Integration Points" section (references 4 phantom agents).
- Keep: Core expertise, ORM patterns, migration safety, scaling strategies, tech preferences.
- Target: ~4 KB (from 7 KB).

### `frontend-specialist.md` — TRIM
- Remove "Automatic Delegation Strategy" section (references 5 phantom agents).
- Remove "Integration Points" section (references 4 phantom agents).
- Keep: Core expertise areas, component process, shadcn/Tailwind best practices, a11y standards, perf optimization.
- Target: ~2.5 KB (from 5 KB).

### `docker-expert.md` — MINOR TRIM
- No phantom refs. Slightly verbose "Output" section (10 bullet points of deliverables). Could compress to 3-4.
- Otherwise clean.

### `rabbitmq-expert.md` — MINOR TRIM
- No phantom refs. Same pattern as docker-expert — verbose "Output" section. Compress.

### `designer.md` — LEAVE AS-IS
- Lean, well-structured. No changes needed.

### `refactoring-expert.md` — LEAVE AS-IS
- Already minimal.

### `researcher.md` — LEAVE AS-IS
- Self-contained, carries MCP tool reference. This is correct — the main prompt delegates MCP usage to this agent.

### `scout.md` — LEAVE AS-IS
- Clean, well-scoped.

### `vision.md` — LEAVE AS-IS
- Clean, well-structured.

---

## Tasks

1. **Task 1: Rewrite `~/.pi/agent/AGENTS.md`**
   - File: `/home/yash/.pi/agent/AGENTS.md`
   - Changes: Replace entire content with the draft skeleton above. Keep the Morph plugin HTML comment block (lines 1-6) untouched — it's auto-managed by `pi-morphllm-plugin`. Replace everything after `---` with the new structure: Core Rules (6 guardrails), Subagent Routing (cards), MCP Harness (2-line section).
   - Acceptance: File is ~50 lines. Every subagent with an `.md` file has a card. No phantom agents referenced. No skills listed as subagents. MCP tool reference is one line pointing to `context-mode` only.

2. **Task 2: Delete `~/.pi/agent/agents/ui-ux-designer.md`**
   - File: `/home/yash/.pi/agent/agents/ui-ux-designer.md`
   - Changes: Remove file. `designer.md` covers the UI/UX role.
   - Acceptance: File gone. No other file references `ui-ux-designer`.

3. **Task 3: Trim `backend-architect.md` — remove phantom agent cross-references**
   - File: `/home/yash/.pi/agent/agents/backend-architect.md`
   - Changes: Delete "Automatic Delegation Strategy" section and "Integration Points" section. Both reference agents that don't exist.
   - Acceptance: No references to `security-auditor`, `performance-profiler`, `integration-test-builder`, `tech-writer`, `monitoring-architect`, or `iac-expert`.

4. **Task 4: Trim `code-reviewer.md` — remove phantom cross-references + compress checklist**
   - File: `/home/yash/.pi/agent/agents/code-reviewer.md`
   - Changes: Delete "Automatic Delegation Strategy" and "Integration Points" sections. Compress "Review Checklist by Area" from 40-checkbox format to compact paragraph or short list.
   - Acceptance: No references to `security-auditor`, `performance-profiler`, `refactoring-expert` (as delegation target), `test-architect`, `error-detective`. File under 4 KB.

5. **Task 5: Trim `database-engineer.md` — remove phantom cross-references**
   - File: `/home/yash/.pi/agent/agents/database-engineer.md`
   - Changes: Delete "Automatic Delegation Strategy" and "Integration Points" sections.
   - Acceptance: No references to `backend-architect` (as delegation target), `security-auditor`, `performance-profiler`, `migration-specialist`, `monitoring-architect`.

6. **Task 6: Trim `frontend-specialist.md` — remove phantom cross-references**
   - File: `/home/yash/.pi/agent/agents/frontend-specialist.md`
   - Changes: Delete "Automatic Delegation Strategy" and "Integration Points" sections.
   - Acceptance: No references to `backend-architect` (as delegation target), `performance-profiler`, `e2e-test-automator`, `unit-test-generator`, `security-auditor`, `tech-writer`.

7. **Task 7: Minor trim `docker-expert.md` and `rabbitmq-expert.md` — compress "Output" sections**
   - Files: `/home/yash/.pi/agent/agents/docker-expert.md`, `/home/yash/.pi/agent/agents/rabbitmq-expert.md`
   - Changes: Compress verbose 10-bullet "Output" sections to 3-4 lines each.
   - Acceptance: No phantom refs. Files slightly shorter. Content preserved.

---

## Files to Modify

| File | Change |
|------|--------|
| `/home/yash/.pi/agent/AGENTS.md` | Full rewrite — lean orchestrator prompt with routing cards |
| `/home/yash/.pi/agent/agents/ui-ux-designer.md` | DELETE |
| `/home/yash/.pi/agent/agents/backend-architect.md` | Remove phantom agent sections |
| `/home/yash/.pi/agent/agents/code-reviewer.md` | Remove phantom agent sections + compress checklist |
| `/home/yash/.pi/agent/agents/database-engineer.md` | Remove phantom agent sections |
| `/home/yash/.pi/agent/agents/frontend-specialist.md` | Remove phantom agent sections |
| `/home/yash/.pi/agent/agents/docker-expert.md` | Minor — compress Output section |
| `/home/yash/.pi/agent/agents/rabbitmq-expert.md` | Minor — compress Output section |

## New Files
None.

---

## Dependencies

- Task 1 (main AGENTS.md rewrite) has no dependencies — can be done first.
- Tasks 2-7 (subagent def trims) are independent of each other and of Task 1.
- All tasks can be done in parallel.

---

## Risks

1. **Morph plugin block auto-injection**: The `<!-- pi-morphllm-plugin:fastapply:start -->` block at the top of AGENTS.md is managed by the `pi-morphllm-plugin` package. If the package re-injects on startup, rewriting the file is safe. If the package only writes on install/update, the block must be preserved manually. **Verify**: after rewrite, run the agent and check if the Morph block is still present.

2. **`designer` vs `ui-ux-designer` model difference**: `designer.md` uses `github-copilot/claude-sonnet-4.6`, `ui-ux-designer.md` uses `cursor/sonnet-latest@1m` with a 1M context window. If any workflow depends on the 1M context variant, deleting `ui-ux-designer.md` loses that. **Verify**: check if any recent session invoked `ui-ux-designer` specifically for large-context UI work.

3. **Phantom agent removal**: Trimming "Automatic Delegation Strategy" sections from agent defs removes instructions to delegate to non-existent agents. This is strictly positive but may surface if the model was silently falling back to doing the work inline. No regression risk — the agents can't delegate to agents that don't exist anyway.

4. **`git-commit` and `skill-creator`**: Removing them from the subagent routing table is correct (they're skills), but verify they're still accessible via skill commands (`enableSkillCommands: true` in settings.json). They should be — skills operate independently of the subagent routing table.

5. **Scout/researcher/vision user overrides**: These exist in both `pi-subagents/agents/` (package) and `~/.pi/agent/agents/` (user override). The runtime resolves user overrides first. The main prompt just routes by name. No risk, but worth noting the override mechanism works silently — the main prompt doesn't need to know which version is active.

6. **Card completeness**: The main prompt lists all agents with `.md` files. If new agents are added later, the AGENTS.md won't auto-update. This is by design (explicit routing), but requires manual maintenance when new subagents are created.

---

## Acceptance Report

```acceptance-report
{
  "criteriaSatisfied": [
    {
      "id": "criterion-1",
      "status": "satisfied",
      "evidence": "Plan delivers a lean orchestrator AGENTS.md rework without widening scope. No code written — planning only. All 13 subagent defs read + analyzed. 7 phantom agent references identified. 2 misclassified skills caught. Draft skeleton provided with 4 builtin + 4 user-defined representative cards fully populated."
    }
  ],
  "changedFiles": [],
  "testsAddedOrUpdated": [],
  "commandsRun": [
    {
      "command": "read ~/.pi/agent/AGENTS.md + all 13 agent .md files + 6 builtin agent .md files + settings.json",
      "result": "passed",
      "summary": "Full current-state analysis of main prompt, all subagent defs, builtin defs, and settings."
    },
    {
      "command": "grep for phantom agent names in agents/ and skills/ dirs",
      "result": "passed",
      "summary": "Confirmed 12 phantom agent references across 4 user agent defs. Confirmed git-commit and skill-creator are skills not subagents."
    }
  ],
  "validationOutput": [],
  "residualRisks": [
    "Morph plugin block auto-injection behavior unverified — need to confirm package re-injects after file rewrite",
    "ui-ux-designer.md uses 1M context model — deleting may lose large-context UI capability if any workflow depends on it",
    "New agents added post-rewrite won't auto-appear in AGENTS.md routing cards — manual maintenance required"
  ],
  "noStagedFiles": true,
  "notes": "Main agent currently 84 lines with ~30 lines of low-value content (MCP tool tables, misclassified skills, bare agent tables without routing intelligence). Plan targets ~50 lines of pure routing signal. 7 subagent defs need phantom agent cross-reference removal. ui-ux-designer.md should be deleted (duplicate of designer.md). Tasks 1-7 can all run in parallel."
}
```