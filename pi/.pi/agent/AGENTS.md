# Agent Instructions

<!-- pi-morphllm-plugin:fastapply:start -->
Morph FastApply: Use native edit for small exact replacements.
Use `morph_fastapply` only after reading the target file and
preparing marker-wrapped snippets with `// ... existing code ...`
for large/scattered edits. Fall back to edit/write if needed.
<!-- pi-morphllm-plugin:fastapply:end -->

---

## Core Rules

- Keep context lean. Prefer fresh subagents with explicit task +
  context. Fork only for inherited decisions or visual content.
- Never paste raw output into chat (logs, tests, docs, JSON, git
  history, broad search). Use context-mode.
- Before large implementation: run `scout`; pass exact findings to
  `worker`/`fixer`.
- Reviews must inspect repo/diff directly — never rely on parent
  summary alone.

---

## Tool Routing

Use **first matching rule**. Do not fall through to lower-signal
sources.

**1. `mcp:context7` — Library/framework/SDK docs**

Triggers: API usage, config, options, examples, migrations, version
behavior. Do NOT read `node_modules/` for docs unless Context7
lacks the needed source detail.

**2. `mcp:tavily` — Current web facts / discovery**

Triggers: latest version, deprecation, comparison, announcement,
ecosystem status, recent issue. Use targeted queries; stop after
enough primary evidence.

**3. `mcp:firecrawl` — Specific URL / site extraction**

Triggers: scrape/read URL, docs site, changelog, blog series,
sitemap/crawl, hard-to-extract page. Prefer single-page scrape;
map/crawl only when one page is insufficient.

**4. `mcp:context-mode` — Large or repetitive output**

Triggers: output >20 lines, logs, JSON, test output, coverage, git
history, search results. Process/summarize; do not dump raw bytes.

**5. `scout` — Local repo understanding**

Triggers: unknown codebase flow, broad search, architecture, many
files.

**Avoid:**

- `node_modules/` for normal docs lookup
- Web search when Context7 answers library docs
- Firecrawl crawl when Tavily or one scrape is enough
- Installing packages before checking existing config/package
  metadata

---

## Subagents

**`observer`** _(fork)_ — Images, screenshots, PDFs, diagrams,
terminal output.

**`designer`** — UI/UX, layout, accessibility, animation, visual
polish.

**`fixer`** _(fresh)_ — Bounded edits/tests/bulk changes. Must
include scope, pattern/example, exact change, acceptance criteria.

**`oracle`** _(fork)_ — Risky architecture, ambiguity, high-stakes
decisions.

**`reviewer`** _(fresh)_ — Code review. Pass diff/files and focus
area.

**`scout`** _(fresh)_ — Codebase recon. Request compressed
files/symbols/risks.

**`researcher` + `scout`** _(parallel)_ — External + local
research; parent synthesizes.

---

## Fixer Contract

Invoke `fixer` **only when fully scoped**. Required inputs:

1. Files/folders in scope
2. Pattern or example of the change
3. Exact change to make
4. Acceptance/verification criteria

If any input is unclear → ask the user or run `scout` first.
