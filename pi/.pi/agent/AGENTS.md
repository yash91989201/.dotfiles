# Agent Instructions

<!-- pi-morphllm-plugin:fastapply:start -->
Morph FastApply: native edit for small exact replacements. `morph_fastapply`
only for large/scattered edits, after reading target file, using
marker-wrapped anchor snippets (`// ... existing code ...`). Fall back to
edit/write if it fails.
<!-- pi-morphllm-plugin:fastapply:end -->

---

## Core Rules

- Delegate early and often — if a task fits a subagent's role, hand it off rather than doing it inline.
  Each subagent runs in its own context, which keeps the main context lean.
- Fresh subagent per task; fork only when the task needs inherited context or visual content.
- Never paste raw output into chat (logs, JSON, test output, git history) — route through `context-mode`.
- Before large implementation work: run `scout` first, then pass findings to `worker`.
- Reviews must inspect the repo/diff directly — never trust the parent's summary.

---

## Routing

| Trigger | Route | Call style |
| - | - | - |
| Web search, docs, API refs, library docs | `researcher` | subagent |
| Unknown codebase flow, architecture, broad local search | `scout` | subagent |
| Both needed (e.g. "how does X work + how do we do it") | `researcher` + `scout` | subagent |
| Output >20 lines: logs, JSON, tests, history, dumps | `context-mode` | `mcp()` call |

---

## Subagents

`fresh` = new session, no inherited context · `fork` = inherits parent context

**Fork**

| Agent | Role |
| - | - |
| `planner` | Creates implementation plans from context and requirements |
| `worker` | Implementation — handles normal tasks and approved oracle handoffs |
| `oracle` | Decision-consistency oracle — protects inherited state, prevents drift |
| `designer` | UI/UX + visual implementation — hierarchy, color, spacing, motion, a11y |
| `vision` | Read-only visual analysis — images, screenshots, PDFs, diagrams |

**Fresh**

| Agent | Role |
| - | - |
| `context-builder` | Analyzes requirements + codebase, generates context and meta-prompt |
| `delegate` | Lightweight passthrough — inherits parent model, no default reads |
| `scout` | Fast codebase recon — returns compressed files/symbols/risks |
| `reviewer` | Plan review, PR/issue validation, solution review |
| `researcher` | Autonomous research via tavily/context7/firecrawl — returns `research.md` |
| `code-reviewer` | Code quality, security vulnerabilities, consistency, best practices |
| `backend-architect` | API architecture, auth, database schemas, microservices |
| `database-engineer` | Schema design, query optimization, migrations, data integrity |
| `docker-expert` | Containerization, image builds, orchestration |
| `frontend-specialist` | shadcn/ui components, Tailwind, WCAG accessibility, React performance |
| `refactoring-expert` | Tech debt reduction, design patterns, code simplification |
| `rabbitmq-expert` | RabbitMQ messaging, config, optimization |
| `git-commit` | Conventional commit analysis, staging, message generation |
| `skill-creator` | Create, modify, and benchmark skills |

---

## MCP Tool Calling

```js
mcp({ tool: "FULL_TOOL_NAME", args: '{"key":"value"}' })
```

`args` is a JSON string. Tool name = `{server}_{tool}`.

| Server | Tools |
| - | - |
| `context-mode` | `context_mode_ctx_execute`, `context_mode_ctx_fetch_and_index`, `context_mode_ctx_search`, `context_mode_ctx_batch_execute` |

```js
mcp({ tool: "context_mode_ctx_search", args: '{"queries": ["..."]}' })
mcp({ tool: "context_mode_ctx_execute", args: '{"language": "javascript", "code": "..."}' })
```
