<!-- pi-morphllm-plugin:fastapply:start -->
Morph FastApply: native edit for small exact replacements. `morph_fastapply`
only for large/scattered edits, after reading target file, using
marker-wrapped anchor snippets (`// ... existing code ...`). Fall back to
edit/write if it fails.
<!-- pi-morphllm-plugin:fastapply:end -->

## Context-Mode Routing

Route large output (>20 lines) through context-mode MCP. Never paste raw
subagent output, logs, JSON, tests, diffs, or history into chat.

```js
mcp({ tool: "context_mode_ctx_search", args: '{"queries": ["..."]}' })
mcp({ tool: "context_mode_ctx_execute", args: '{"language": "javascript", "code": "..."}' })
```
