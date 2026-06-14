# Agent Instructions

<!-- pi-morphllm-plugin:fastapply:start -->
Morph FastApply: Use native edit for small exact replacements. Use
`morph_fastapply` only after reading target file and preparing marker-wrapped
snippets with `// ... existing code ...` for large/scattered edits. Fall back
to edit/write if needed.
<!-- pi-morphllm-plugin:fastapply:end -->
---

## Core

- Keep context lean. Prefer fresh subagents with explicit task/context.
  Fork only for inherited decisions or visual content.
- Never paste large outputs: logs, tests, docs, JSON, git history, broad
  search results. Use context-mode.
- Before large implementation: run `scout`; hand exact findings to
  `worker`/`fixer`.
- Reviews inspect repo/diff directly; never rely on parent summary only.

## Tool Routing

Use first matching rule. Do not waste time with lower-signal sources.

1. **Library/framework/SDK docs** → `mcp:context7`
   - Triggers: API usage, config, options, examples, migrations,
     version behavior.
   - Do **not** read `node_modules/` for docs unless Context7 lacks
     needed source detail.
2. **Current web facts / discovery** → `mcp:tavily`
   - Triggers: latest version, deprecation, comparison, announcement,
     ecosystem status, recent issue.
   - Use targeted queries; stop after enough primary evidence.
3. **Specific URL / site extraction** → `mcp:firecrawl`
   - Triggers: scrape/read URL, docs site, changelog page, blog series,
     sitemap/crawl, hard-to-extract page.
   - Prefer single-page scrape; map/crawl only when one page insufficient.
4. **Large or repetitive output** → `mcp:context-mode`
   - Triggers: output >20 lines, logs, JSON, test output, coverage,
     git history, search results.
   - Process/summarize; do not dump raw bytes into chat.
5. **Local repo understanding** → `scout`
   - Triggers: unknown codebase flow, broad search, architecture, many files.

Avoid:

- `node_modules/` for normal docs lookup.
- Web search when Context7 answers library docs.
- Firecrawl crawl when Tavily search or one scrape is enough.
- Installing packages before checking existing config/package metadata.

## Subagents

- `observer` fork: images, screenshots, PDFs, diagrams, terminal output.
- `designer`: UI/UX, layout, accessibility, animation, visual polish.
- `fixer` fresh: bounded edits/tests/bulk changes. Must include scope,
  pattern/example, exact change, acceptance.
- `oracle` fork: risky architecture, ambiguity, high-stakes decisions.
- `reviewer` fresh: code review with diff/files and focus.
- `scout` fresh: codebase reconnaissance; request compressed
  files/symbols/risks.
- `researcher` + `scout` parallel: external + local research;
  parent synthesizes.

## Fixer Contract

Invoke `fixer` only when fully scoped:

1. Files/folders allowed
2. Pattern/example
3. Exact change
4. Acceptance/verification

If unclear, ask user or run `scout` first.
