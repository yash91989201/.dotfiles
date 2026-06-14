<!-- pi-morphllm-plugin:fastapply:start -->
Morph FastApply: Use native edit for small exact replacements.
Use `morph_fastapply` only after reading target file and preparing
marker-wrapped snippets with `// ... existing code ...` for
large/scattered/whitespace-sensitive existing-file edits.
Fall back to edit/write if needed.
<!-- pi-morphllm-plugin:fastapply:end -->
---

## Global Workflow

Keep main context lean. Prefer fresh subagents with explicit task +
context over forking the full chat. Fork only when inherited decisions
or visual content are essential.

---

## Subagent Routing

### `observer` · `fork`

Images, screenshots, PDFs, diagrams, terminal output.

### `designer`

UI/UX, layout, accessibility, animation, visual polish.
Pass exact files/screenshots and constraints.

### `fixer` · `fresh`

Bounded edits, tests, repetitive/bulk changes.
See [Fixer Contract](#fixer-contract) before invoking.

### `oracle` · `fork`

Risky architecture, ambiguous decisions, high-stakes review.

### `reviewer` · `fresh`

Code review. Pass diff/files and explicit focus area.

### `scout` · `fresh`

Codebase reconnaissance. Request compressed
files/symbols/risks in the handoff.

### `researcher` + `scout` · parallel

External + local research. Synthesize results in parent.

---

## Context Rules

- **Never** paste large outputs (logs, tests, docs, JSON, git history,
  broad search results) into chat — use context-mode tools.
- Before any large implementation: run `scout` first, then hand off
  exact context to `worker`/`fixer`.
- Reviews must inspect repo/diff directly — do not rely on parent
  chat state.

---

## Fixer Contract

Only invoke `fixer` when the task is fully scoped.
Every `fixer` handoff **must** include:

1. **Files/folders** — allowed scope (no implicit expansion)
2. **Pattern/example** — what the change looks like
3. **Exact change** — what to do, not just what to achieve
4. **Acceptance/verification** — how to confirm success

> If scope is unclear → ask the user **or** run `scout` first.
> Do not guess.
