<!-- pi-morphllm-plugin:fastapply:start -->
Morph FastApply: Use native edit for small exact replacements. Use morph_fastapply only after reading target file and preparing marker-wrapped snippets with // ... existing code ... for large/scattered/whitespace-sensitive existing-file edits. Fall back to edit/write if needed.
<!-- pi-morphllm-plugin:fastapply:end -->

## Global workflow

Keep main context lean. Prefer fresh subagents with explicit task/context over forking full chat. Use fork only when inherited decisions or visual content matter.

## Subagent routing

- Images, screenshots, PDFs, diagrams, terminal screenshots → `observer`, `context: "fork"`.
- UI/UX, layout, accessibility, animation, visual polish → `designer`; pass exact files/screenshots and constraints.
- Bounded edits, tests, repetitive/bulk changes → `fixer`, `context: "fresh"`; include scope, pattern, acceptance.
- Risky architecture, ambiguous decisions, final high-stakes review → `oracle`, `context: "fork"`.
- Code review → `reviewer`, prefer `context: "fresh"` with diff/files and explicit focus.
- Codebase reconnaissance → `scout`, `context: "fresh"`; ask for compressed files/symbols/risks.
- External + local research → run `researcher` and `scout` in parallel; synthesize in parent.

## Context rules

- Do not paste large outputs into chat. Use context-mode tools for logs, tests, docs, JSON, git history, and broad searches.
- Before large implementation: scout first, then handoff exact context to worker/fixer.
- After long phase: `/compact` or write `HANDOFF.md`, then start fresh with only handoff path.
- Reviews should inspect repo/diff directly, not rely on parent chat.

## Fixer contract

Use fixer only when task is well-scoped. Provide:

- files/folders allowed
- pattern/example
- exact change
- acceptance/verification

If scope unclear, ask or scout first.
