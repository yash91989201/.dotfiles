# PI CLI Setup Review

## Files Retrieved

### Core Config
1. `settings.json` (lines 1-100) — root configuration: packages, skills, prompts, model lists, subagent overrides, UI settings
2. `morph.json` (lines 1-100) — Morph plugin config: API key routing, edit/search modes, timeouts, compact thresholds
3. `morph.env` (lines 1-1) — API key for morph plugin
4. `auth.json` (lines 1-100) — OAuth/API keys for 6 providers: openai-codex, xiaomi, google-ai-pro, cursor, fireworks, context7
5. `mcp.json` (lines 1-100) — MCP server definitions: context-mode, context7, tavily, firecrawl
6. `AGENTS.md` (lines 1-100) — global workflow rules, subagent routing table, fixer contract

### Agents
7. `agents/designer.md` (lines 1-100) — UI/UX specialist with gemini-3.1-pro-preview
8. `agents/fixer.md` (lines 1-100) — fast execution specialist with kimi-k2p6-turbo
9. `agents/observer.md` (lines 1-100) — visual analysis agent with gemini-2.5-pro

### Prompts
10. `prompts/oracle.md` (lines 1-10) — high-value architecture review with gpt-5.5 high
11. `prompts/scout-context.md` (lines 1-10) — codebase scout with kimi-k2p6-turbo low
12. `prompts/worker-implement.md` (lines 1-10) — implement with minimax-m2p7 low
13. `prompts/research-plan.md` (lines 1-10) — research then plan with kimi-k2p6 medium
14. `prompts/quick-fix.md` (lines 1-10) — fast routine fix with kimi-k2p6 medium
15. `prompts/deep-debug.md` (lines 1-10) — root-cause debugging with gpt-5.5 high
16. `prompts/implement-review.md` (lines 1-10) — chain: scout -> worker -> review-diff
17. `prompts/review-diff.md` (lines 1-10) — git diff review with gpt-5.4-mini medium

### Skills
18. `skills/find-skills/SKILL.md` (lines 1-100) — discover and install skills from skills.sh
19. `skills/git-commit/SKILL.md` (lines 1-100) — conventional commit message generation

### Extensions
20. `extensions/google-ai-pro/index.ts` (lines 1-100) — custom Google Code Assist/Gemini CLI provider extension
21. `extensions/google-ai-pro/auth.json` (lines 1-10) — OAuth client credentials for Google AI Pro
22. `extensions/image-placeholders/index.ts` (lines 1-100) — paste image placeholders in editor

### Package/Theme
23. `npm/package.json` (lines 1-30) — 14 package dependencies
24. `themes/tokyonight-night.json` (lines 1-100) — Tokyo Night theme definition

### Cache/State
25. `cursor-model-cache.json` (lines 1-100) — Cursor model metadata cache
26. `cursor-sdk-model-list.json` (lines 1-100) — Cursor SDK model list
27. `cursor-proxy.json` (lines 1-10) — Cursor proxy: port 39017, pid 128871
28. `mcp-cache.json` (lines 1-100) — Cached MCP tools: Tavily (5 tools), context-mode (13 tools)
29. `mcp-npx-cache.json` (lines 1-30) — NPX binary cache for tavily-mcp and firecrawl-mcp

## Key Code

### Installed Packages (14)
```json
{
  "dependencies": {
    "@juicesharp/rpiv-ask-user-question": "^1.19.1",
    "@juicesharp/rpiv-btw": "^1.19.1",
    "@juicesharp/rpiv-todo": "^1.19.1",
    "@schultzp2020/pi-cursor": "^0.5.0",
    "context-mode": "^1.0.162",
    "pi-caveman": "^1.0.7",
    "pi-gitnexus": "^0.6.3",
    "pi-mcp-adapter": "^2.9.0",
    "pi-morphllm-plugin": "^0.1.9",
    "pi-powerline-footer": "^0.6.1",
    "pi-slipstream-compact": "^0.1.1",
    "pi-subagents": "0.25.0",
    "pi-total-recall": "^1.8.1"
  }
}
```

### Enabled Models
```json
[
  "xiaomi/mimo-v2.5",
  "xiaomi/mimo-v2.5-pro",
  "cursor/composer-2.5",
  "cursor/gpt-5.3-codex",
  "cursor/claude-4.6-sonnet-medium-thinking",
  "openai-codex/gpt-5.4-mini",
  "openai-codex/gpt-5.5",
  "fireworks/accounts/fireworks/models/kimi-k2p6",
  "fireworks/accounts/fireworks/routers/kimi-k2p6-turbo",
  "fireworks/accounts/fireworks/models/minimax-m2p7"
]
```

### Subagent Overrides
```json
{
  "oracle": { "model": "openai-codex/gpt-5.5", "thinking": "high" },
  "researcher": { "model": "fireworks/accounts/fireworks/routers/kimi-k2p6-turbo", "thinking": "low" },
  "scout": { "model": "fireworks/accounts/fireworks/routers/kimi-k2p6-turbo", "thinking": "low" },
  "worker": { "model": "fireworks/accounts/fireworks/models/minimax-m2p7", "thinking": "low" },
  "reviewer": { "model": "openai-codex/gpt-5.4-mini", "thinking": "medium" }
}
```

### MCP Servers
- `context-mode` — direct tools, local execution
- `context7` — lazy, requires CONTEXT7_API_KEY
- `tavily` — lazy, direct tools, requires TAVILY_API_KEY
- `firecrawl` — lazy, direct tools, requires FIRECRAWL_API_KEY

### Google AI Pro Extension
- Custom provider: `google-ai-pro` with OAuth flow
- Models: gemini-3-pro-preview, gemini-3.1-pro-preview, gemini-3.5-flash, gemini-2.5-pro, gemini-2.5-flash, gemini-3.1-flash-lite
- Zero cost (uses Google AI Pro subscription)
- Handles tool-call thought signatures, multimodal responses, image placeholders

### Image Placeholders Extension
- Replaces pasted image paths with `[Img N - SIZE]` markers
- Uses private-use Unicode characters for atomic backspace
- Expands to real paths on submit
- Theme-aware styling (Tokyo Night `bgVisual`)

## Architecture

```
PI CLI Core
├── Config Layer (settings.json, morph.json, auth.json, mcp.json)
├── Agent Layer (agents/ — only 3 definitions, prompts/ — 8 templates)
├── Skill Layer (skills/ — 2 skills, external via npx skills)
├── Extension Layer (extensions/ — 2 custom extensions)
├── Package Layer (npm/ — 14 installed packages)
├── MCP Layer (context-mode, tavily, firecrawl, context7)
├── Theme Layer (themes/ — 1 theme)
└── State Layer (sessions/, run-history.jsonl, progress.md)

External Services
├── OpenAI Codex (OAuth, default provider)
├── Fireworks (API key, kimi + minimax models)
├── Google AI Pro (OAuth, custom extension)
├── Cursor (OAuth, proxy on :39017)
├── Xiaomi (API key, mimo models)
└── Tavily/Firecrawl (API keys, web search)
```

## How Pieces Fit

1. **Settings.json** is the orchestrator — it declares which packages to load, which skills/prompts paths to use, and which models are enabled.
2. **Morph.json** configures the Morph plugin (edit routing, search routing, timeouts, compact behavior).
3. **Agents/** contains full agent definitions (designer, fixer, observer) with models, tools, and system prompts.
4. **Prompts/** contains short prompt templates for other agents (oracle, scout, worker, researcher, reviewer) that are referenced by settings.json subagent overrides.
5. **Skills/** are loaded when the user asks domain-specific questions (git commits, finding skills).
6. **Extensions/** are loaded at startup and register custom providers or UI components.
7. **MCP servers** are started on-demand (lazy) and provide external tools (web search, context execution, knowledge base).
8. **Context-mode** is the heavy-lifter for sandboxed execution, knowledge indexing, and search.

## Strengths

- **Multi-provider redundancy** — 6 providers, 10+ models; if one fails, others available
- **Context-mode ecosystem** — sandboxed execution, knowledge base, auto-indexing, batch execution
- **Rich MCP tools** — Tavily (search, extract, crawl, map, research), Context7 (documentation), context-mode (13 tools)
- **Custom extensions** — Google AI Pro provider is well-crafted with OAuth, thought signatures, multimodal handling
- **Subagent specialization** — 5 distinct roles with model/thinking overrides
- **Image placeholder UX** — clean clipboard image handling with themed styling
- **Workflow rules** — clear AGENTS.md contract for orchestration
- **Theme support** — Tokyo Night theme with full color palette

## Bottlenecks

- **Missing agent definitions** — `agents/` only has 3 files (designer, fixer, observer). `oracle`, `scout`, `researcher`, `worker`, `reviewer` only exist as prompts in `prompts/`. This means subagent overrides reference prompts, not full agents.
- **pi-subagent conflict** — user reported inability to use kimi models due to `pi-subagent` package (version 0.25.0). This package is installed but may conflict with Fireworks router models.
- **Timeout tightness** — morph.json: `timeoutMs: 30000`, `warpGrepTimeoutMs: 60000`, `compactTimeoutMs: 60000`. Long operations may hit these.
- **Stats dashboard disabled** — `statsDashboard.enabled: false` in morph.json
- **No default web search** — Tavily/Firecrawl require explicit tool calls; no automatic research augmentation
- **Single theme** — only Tokyo Night available

## Redundancies

- **Duplicate web search** — Tavily and Firecrawl both provide search/crawl; likely only one needed
- **Cursor model cache + SDK list** — two files tracking Cursor models (`cursor-model-cache.json` and `cursor-sdk-model-list.json`)
- **Multiple thinking configurations** — every model variant has reasoning/thinking/effort levels, creating combinatorial explosion
- **OAuth vs API key** — both `auth.json` and `morph.env` store credentials; different formats increase management surface
- **Context7 + tavily** — both provide documentation/web content; overlap in knowledge acquisition

## Missing Capabilities

- **Testing agent** — no `tester` or `qa` agent for automated test generation/execution
- **Security agent** — no `security` or `audit` agent for vulnerability scanning
- **DevOps agent** — no `deployer` or `infra` agent for deployment/config management
- **Documentation agent** — no `docs` agent for README/API doc generation
- **Migration agent** — no `migrator` for framework/library version upgrades
- **Performance agent** — no `profiler` for bottleneck analysis
- **Backup of auth.json** — no encrypted or backup mechanism for credentials
- **Agent fallback** — no fallback model when a provider is unavailable
- **Web search agent** — no dedicated `researcher` agent definition (only a prompt)
- **Local LLM support** — no Ollama/local model provider configured

## Risks

- **Credential exposure** — `auth.json` contains 6 provider tokens in plaintext; `morph.env` has API key; `extensions/google-ai-pro/auth.json` has OAuth client secret. All in ~/.pi/agent/.
- **Google AI Pro policy risk** — extension README notes: "Google has warned that Gemini CLI OAuth via third-party software may be policy-sensitive"
- **Cursor proxy running** — `cursor-proxy.json` shows port 39017 with pid 128871; if exposed externally, could be a vector
- **pi-subagent model conflict** — Fireworks router `kimi-k2p6-turbo` may fail when `pi-subagents` package is active
- **Trust scope limited** — `trust.json` only trusts 3 directories; new projects may fail silently
- **No key rotation** — no expiry warnings or auto-refresh for API keys (OAuth tokens have refresh but manual keys do not)
- **Version drift** — `pi-subagents` pinned to `0.25.0` while other packages use `^` ranges; potential incompatibility
- **MCP server failures** — lazy-start means failures only surface at first use; no health check at startup
- **Stats dashboard disabled** — no visibility into context usage or tool performance
- **Empty conversation crash** — Google AI Pro extension throws if empty conversation sent; no guard in orchestrator

## Start Here

**`settings.json`** — this is the root config. It defines the entire package ecosystem, model lists, subagent overrides, and UI behavior. Any changes to agent routing or model selection must go through this file.

## Global PI Config

Parent `~/.pi/` contains:
- `context-mode/` — content index and session databases (FTS5 knowledge base)
- `memory/` — SQLite memory.db with session auto-memory
- `session-search/` — index directory for cross-session search

These are global across all projects and hold the persistent knowledge base that context-mode queries.
