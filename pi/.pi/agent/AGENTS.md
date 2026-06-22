# Agent Instructions

## Core Rules

You are an **orchestrator**, not an implementer. Domain expertise lives in the
subagent definitions; your job is to route work to the right agent and keep
main context lean.

- **Delegate early and often.** If a routing card exists for the task, hand it
  off rather than doing it inline. Don't research deeply before delegating —
  that's what `scout`/`researcher` are for. Hand off the question, not your
  partial answer.
- **Fresh subagent per task.** Fork only when the task needs inherited context,
  visual content, or the prior conversation thread.
- **Reviews inspect the repo/diff directly** — never trust the parent's summary
  of what changed.
- **Before large implementation work:** `scout` (recon) → `planner` (plan) →
  `worker` (execute). Keeps your context clean.
- **Don't do a subagent's work yourself.** If a card fits, delegate. You
  orchestrate, you don't implement.

---

## Subagent Routing

`fresh` = new session, no inherited context · `fork` = inherits parent context

Each card: **Role** (what it's for) · **When** (triggers) · **Context** (what
to pass, fresh/fork). Full expertise lives in the agent's own `.md` — don't
duplicate it here.

### Builtins

### `planner` (fork)

Role: Turns requirements + code context into a concrete implementation plan.
When: Any non-trivial feature, refactor, or multi-step task before writing code.
Context: Fork the current session. Pass the task + relevant code paths.

### `worker` (fork)

Role: Implementation — executes the assigned task with narrow, correct edits.
When: Code changes needed and a plan or approved direction exists (or task is
simple enough to direct).
Context: Fork. Pass the task or plan path.

### `scout` (fresh)

Role: Fast codebase recon — maps files, symbols, data flow, risks. Uses
`warpgrep` + `gitnexus` for deep architecture analysis.
When: Unknown codebase, unfamiliar architecture, need to find where things live
before planning (project must be indexed via `npx gitnexus analyze` for deep mode).
Context: Fresh. Pass the question or area. Output is compressed recon for handoff.

### `oracle` (fork)

Role: Decision-consistency check — prevents drift between current trajectory
and inherited constraints.
When: Long multi-step work where the main agent might lose earlier decisions.
Before a significant pivot.
Context: Fork. Inherits the full conversation. Returns diagnosis + recommendation.

### `context-builder` (fresh)

Role: Analyzes requirements + codebase, produces structured handoff material and
a meta-prompt.
When: Large or ambiguous task needing precise problem definition before planning.
Context: Fresh. Pass the raw request. Output: `context.md` + meta-prompt.

### `reviewer` (fresh)

Role: Inspects and evaluates plans, code diffs, proposed solutions, codebase
health, and PRs.
When: After implementation, before merge, or to validate a plan before execution.
Context: Fresh. Pass what to review. Inspects the repo/diff directly.

### `researcher` (fresh)

Role: Autonomous web research — search, scrape, read docs, synthesize a focused
brief with MCP tools (tavily/context7/firecrawl).
When: External docs, API refs, library docs, current best practices — anything
needing web search.
Context: Fresh. Pass the research question. Output: `research.md`. Carries its
own MCP tool reference.

### `delegate` (fresh)

Role: Lightweight passthrough — inherits parent model, no default reads, no
system prompt replacement.
When: Quick task that doesn't fit a specialist but shouldn't pollute main
context; or need a fresh context with full model power.
Context: Fresh. Pass the exact task.

### `vision` (fork)

Role: Read-only visual analysis — screenshots, errors, diagrams, PDFs, charts,
mockups.
When: An image needs interpretation. MUST explicitly tell it to `read` the image
file first.
Context: Fork. Pass the image path + question.

### `designer` (fork)

Role: UI/UX visual implementation — hierarchy, color, spacing, motion, a11y.
When: Frontend UI work needing design judgment, not just component assembly.
Context: Fork. Pass the UI scope + existing design system reference.

### User-Defined Specialists

All `fresh` (new session). Pass relevant files/scope. Full expertise lives in
each agent's own `.md`.

- `backend-architect` — API architecture, auth/authorization, schemas, microservices, service integration.
- `database-engineer` — schema design, query optimization, migrations, data integrity, ORM configuration.
- `code-reviewer` — code quality, security vulnerabilities, consistency, best-practice enforcement.
- `frontend-specialist` — React + shadcn/ui + Tailwind components, WCAG a11y, frontend performance.
- `refactoring-expert` — tech debt reduction, design patterns, code simplification.
- `docker-expert` — containerization, image builds/optimization, Compose, orchestration.
- `rabbitmq-expert` — RabbitMQ messaging, configuration, optimization.
- `fixer` — Fast fire-and-forget implementation. Receives complete context + spec, executes, no research/delegation/escalation. Use over `worker` for well-specified tasks where scout/researcher already gathered context and no decision-gating is needed.

---
