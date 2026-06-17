# Agent Instructions

<!-- pi-morphllm-plugin:fastapply:start -->
Morph FastApply: native edit for small exact replacements. `morph_fastapply`
only for large/scattered edits, after reading target file, using
marker-wrapped anchor snippets (`// ... existing code ...`). Fall back to
edit/write if it fails.
<!-- pi-morphllm-plugin:fastapply:end -->

---

## Core Rules

- Lean context. Fresh subagent per task, explicit task + context. Fork
  only for inherited decisions or visual content.
- Never paste raw output into chat (logs, tests, docs, JSON, git history,
  search results). Route through `context-mode`.
- Before large implementation: `scout` first, pass exact findings to
  `worker`/`fixer`.
- Reviews inspect repo/diff directly. Never rely on parent summary.
- Research tasks (web search, docs, API refs, library docs) always go to
  `researcher`. It calls tavily/context7/firecrawl internally.

---

## Tool Routing

First matching rule wins. No fallthrough.

| # | Trigger | Route to |
| - | - | - |
| 1 | External: web search, docs, API refs, library docs | `researcher` |
| 2 | Local: unknown codebase flow, architecture, broad search | `scout` |
| 3 | Both needed (e.g. "how does X work, how do we do it") | `researcher` + `scout` |
| 4 | Output >20 lines: logs, JSON, tests, history, search dumps | `context-mode` |

Anti-patterns:

- calling tavily/context7/firecrawl directly from main agent (use `researcher`)
- grepping `node_modules/` for docs
- installing packages before checking existing config/package metadata

---

## MCP Tool Calling

```js
mcp({ tool: "FULL_TOOL_NAME", args: '{"key":"value"}' })
```

`args` is a JSON string. Tool name = `{server}_{tool}` (toolPrefix: "server").
Add new servers as rows below.

| Server | Tool names |
| - | - |
| context-mode | `context_mode_ctx_execute`, `context_mode_ctx_fetch_and_index`, `context_mode_ctx_search`, `context_mode_ctx_batch_execute` |

```js
mcp({ tool: "context_mode_ctx_search", args: '{"queries": ["..."]}' })
mcp({ tool: "context_mode_ctx_execute", args: '{"language": "javascript", "code": "..."}' })
```

Discovery: `mcp({ search: "term" })` · `mcp({ server: "name" })` ·
`mcp({ describe: "tool" })`. Status: `mcp()`. Force connect:
`mcp({ connect: "name" })`.

---

## Subagents

### Builtin

| Agent | Context | Role |
| - | - | - |
| `context-builder` | fresh | Analyzes requirements + codebase, generates context and meta-prompt. |
| `delegate` | fresh | Lightweight. Inherits parent model, no default reads. |
| `planner` | fork | Creates implementation plans from context and requirements. |
| `worker` | fork | Implementation agent for normal tasks and approved oracle handoffs. |
| `oracle` | fork | High-context decision-consistency oracle. Protects inherited state, prevents drift. |
| `scout` | fresh | Fast codebase recon. Returns compressed files/symbols/risks. |
| `reviewer` | fresh | Code review, plan review, solution review, codebase health, PR/issue validation. |

### User-defined

| Agent | Context | Role |
| - | - | - |
| `researcher` | fresh | Autonomous research. Calls tavily/context7/firecrawl. Returns `research.md`. |
| `designer` | fork | UI/UX + visual implementation. Hierarchy, color, spacing, motion, accessibility. |
| `observer` | fork | Read-only visual analysis — images, screenshots, PDFs, diagrams. |
| `code-reviewer` | fresh | Code quality, security vulnerabilities, consistency, best practices. |
| `backend-architect` | fresh | Scalable API architectures, auth systems, database schemas, microservices, API docs. |
| `database-engineer` | fresh | Schema design, query optimization, migrations, data integrity, scaling. |
| `docker-expert` | fresh | Containerization, image creation, orchestration. |
| `frontend-specialist` | fresh | shadcn/ui components, Tailwind CSS, WCAG accessibility, React performance. |
| `ui-ux-designer` | fresh | UI components, responsive design, accessibility, distinctive visual aesthetic. |
| `refactoring-expert` | fresh | Reduce tech debt, maintainability, design patterns, code simplification. |
| `rabbitmq-expert` | fresh | RabbitMQ messaging, configuration, optimization. |
| `git-commit` | fresh | Conventional commit analysis, intelligent staging, message generation. |
| `skill-creator` | fresh | Create, modify, improve skills. Run evals and benchmarks. |

**Context key:** `fresh` = new session, no prior context. `fork` = inherits
parent session context.
