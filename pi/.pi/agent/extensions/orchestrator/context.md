# Code Context

## Files Retrieved

1. `/home/yash/.pi/agent/extensions/orchestrator/index.ts` (842 lines) — full read for verify

## Key Code

- L114-115: `BLOCKED_EDIT_TOOLS={edit,write,morph_fastapply}`, `BLOCKED_RECON_TOOLS={read,grep,find,ls}`
- L119-127: `BLOCKED_RECON_PREFIXES` (ctx_, warpgrep_, gitnexus_, etc.)
- L129: artifact root: `~/.pi/agent/sessions`, segment `/subagent-artifacts/`
- L147-162: `isAllowedReadInput` — realpath + artifact root OR surfaced map
- L165: `surfacedReadAllowlist = new Map<realpath, {mtimeMs, addedAt}>`
- L227-263: `rememberSurfacedRead` — expands `~`, realpath, statSync mtime, cap eviction
- L278-287: `isSurfacedReadAllowed` — re-stat mtime match
- L290-300: `recordSurfacedReadsFromSubagent` — extracts paths from result/output/content/message
- L442-443: `SUBAGENT_INLINE_SUMMARY_INSTRUCTION` — includes "snippets/line numbers inline; avoid path-only answers"
- L645-653: tool_call handler — read bypass via `isAllowedReadInput`, then edit/recon blocks
- L675-687: tool_result handler — `if (!event.isError) recordSurfacedReadsFromSubagent(event)` (success-only)

## Architecture

Hard-block set + bypass allowlist pattern. Edit + recon tools blocked; read gets narrow bypass (artifact files OR surfaced realpath with mtime lock). Surfaced paths populated only on successful subagent tool_result via text extraction.

## Start Here

L643-687 (tool_call + tool_result handlers) — where enforcement and allowlist merge.
