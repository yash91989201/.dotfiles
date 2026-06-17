# Agent Instructions

<!-- pi-morphllm-plugin:fastapply:start -->
Morph FastApply: native edit for small exact replacements. `morph_fastapply`
only for large/scattered edits, after reading target file, using
marker-wrapped snippets (`// ... existing code ...`). Fall back to
edit/write if it fails.
<!-- pi-morphllm-plugin:fastapply:end -->

---

## Core Rules

- Lean context. Fresh subagent per task, explicit task + context. Fork
  only for inherited decisions or visual content.
- Never paste raw output into chat (logs, tests, docs, JSON, git history,
  broad search). Route through `context-mode`.
- Before large implementation: `scout` first, pass exact findings to
  `worker`/`fixer`.
- Reviews inspect repo/diff directly. Never rely on parent summary.

---

## Tool Routing

First matching rule wins. No fallthrough.

| # | Tool | Use when | Don't |
|---|------|----------|-------|
| 1 | `context7` | library/framework/SDK docs: API usage, config, options, examples, migrations, version behavior | don't read `node_modules/` for docs unless context7 lacks source detail |
| 2 | `tavily` | current web facts: latest version, deprecation, comparison, announcement, ecosystem status, recent issue | targeted queries only; stop once evidence is sufficient |
| 3 | `firecrawl` | specific URL/site extraction: scrape/read URL, docs site, changelog, blog series, sitemap/crawl | prefer single-page scrape; map/crawl only if one page insufficient |
| 4 | `context-mode` | large/repetitive output: >20 lines, logs, JSON, test output, coverage, git history, search results | summarize, never dump raw bytes |
| 5 | `scout` | local repo understanding: unknown codebase flow, broad search, architecture, many files | — |

Anti-patterns: `node_modules/` for normal docs; web search when context7
answers it; firecrawl crawl when tavily/single scrape suffices; installing
packages before checking existing config/package metadata.

---

## MCP Tool Calling

Call via proxy: `mcp({ tool: "server_toolname", args: '{"key":"value"}' })`
— `args` is a JSON **string**.

| Server | Lifecycle | Tools |
|--------|-----------|-------|
| context-mode | eager | ctx_execute, ctx_fetch_and_index, ctx_search, ctx_batch_execute |
| context7 | lazy | resolve-library-id, query-docs |
| tavily | lazy | tavily_search, tavily_extract, tavily_crawl, tavily_map, tavily_research |
| firecrawl | lazy | firecrawl_scrape, firecrawl_map, firecrawl_search, firecrawl_crawl, firecrawl_extract |

Naming (`toolPrefix: "server"`): `{server}_{tool}`, e.g.
`tavily_tavily_search`, `firecrawl_firecrawl_scrape`,
`context7_resolve-library-id`, `context_mode_ctx_execute`.

Discovery: `mcp({ search: "term" })` · `mcp({ server: "name" })` ·
`mcp({ describe: "tool" })`. Status: `mcp()`. Force connect:
`mcp({ connect: "name" })`.

Lazy servers connect on first call, disconnect after 10min idle. Tool
metadata cached in `~/.pi/agent/mcp-cache.json` (search/describe work
without live connection).

**Subagent MCP access**: add `mcp` to subagent's `tools:` frontmatter
(e.g. `tools: read, write, mcp, intercom`). Subagent calls tools same way.
Never list individual MCP tool names in `tools:` — they won't register;
the subagent discovers them at runtime via the `mcp` proxy.

---

## Subagents

| Agent | Type | Role |
|-------|------|------|
| `observer` | fork | images, screenshots, PDFs, diagrams, terminal output |
| `designer` | fresh | UI/UX, layout, accessibility, animation, visual polish |
| `fixer` | fresh | bounded edits/tests/bulk changes — see contract below |
| `oracle` | fork | risky architecture, ambiguity, high-stakes decisions |
| `reviewer` | fresh | code review; pass diff/files + focus area |
| `scout` | fresh | codebase recon; request compressed files/symbols/risks |
| `researcher`+`scout` | parallel | external + local research; parent synthesizes |

### Fixer Contract

Invoke only when fully scoped. Required:

1. Files/folders in scope
2. Pattern or example of the change
3. Exact change to make
4. Acceptance/verification criteria

Missing any → ask user or run `scout` first.
