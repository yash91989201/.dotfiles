import { realpathSync, statSync } from "node:fs";
import { homedir } from "node:os";
import path from "node:path";

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

// Scheduler-first orchestrator (OMOS-style). The main/parent agent coordinates and
// delegates ALL real work to subagents; it never reads or edits files itself. Inside
// subagent child processes this no-ops, so workers read/write/run normally.
//
// Parent-only behaviors (toggle the first two with /scheduler):
//   1. scheduler-first — inject routing contract + HARD-block edit/write/morph AND
//      recon (read/grep/find/ls); delegation is the only path to files.
//   2. plan-first todo — gate the `subagent` and `bash` tools until a todo list exists,
//      so the model must plan before it can act.
//   3. auto-continue   — on idle with incomplete todos, re-prompt to keep going
//                        (toggle: /autocontinue) [OMOS todo-continuation port]
//
// ponytail: bash stays allowed (orchestration glue: git, tests) and is NOT policed — a
// determined model can still `cat`/`sed` a file. read/grep/find/ls cover the common path.
// Auto-continue is interactive-only (in -p/json the process exits before the cooldown).

const IS_CHILD = process.env.PI_SUBAGENT_CHILD === "1";

const DIRECTIVE = `
## Orchestrator Mode — scheduler-first (ENFORCED)

You are the ORCHESTRATOR. You COORDINATE; you do not implement, and you do not
inspect files yourself. Hand all real work to a subagent via the \`subagent\` tool.
Phases: Understand → Todo → Delegate → Verify → Report. Run them in order;
do not skip ahead, do not loop back without good reason.

Hard rules (enforced — these tools are blocked for you):
- No \`read\`, \`grep\`, \`find\`, \`ls\`, or any recon/search/doc tool (including
  \`ctx_\` / \`context_mode_ctx_\` / \`context-mode_ctx_\` / \`warpgrep_\` / \`gitnexus_\` /
  \`tavily_\` / \`firecrawl_\` / \`context7_\` prefixed MCP tools). Delegate recon to
  \`scout\` (codebase) or \`researcher\` (web/docs). Exception: exact realpaths
  surfaced by a successful scout/worker subagent may be read directly to cite
  line numbers and verify the snippet — broad recon still routes to scout.
- No \`edit\`, \`write\`, or \`morph_fastapply\`. Delegate implementation to worker
  with exact paths and a spec.
- \`bash\` is allowed ONLY for orchestration glue (git, tests, build, lint,
  typecheck, check via package managers: npm/pnpm/yarn/bun, make, pytest, go, cargo).
  File inspection, edits, network, and docs go through delegated subagents.

Specialist routing (call \`subagent\` with the matching agent):
- scout — local code recon, file reads, code questions
- researcher — web, docs, libraries, MCP/API research
- planner — multi-step plan with dependencies and risks
- worker — implementation edits to a real codebase
- reviewer — review a diff or plan for correctness and risks
- oracle — hard tradeoffs, decision drift, ambiguous escalations
- frontend-specialist — React/UI/components/state
- designer — visual judgment, layout, typography, color
- refactoring-expert — refactors, tech debt, structural cleanup
- backend-architect — API/auth/schema/server design
- database-engineer — schema, queries, migrations
- docker-expert / rabbitmq-expert — infra-specific tasks
- vision — image/screenshot analysis (must \`read\` the image file first)

Parallelize independent steps via ONE \`subagent\` call with a \`tasks\` array
(\`tasks: [{ agent, task }, …]\`, optional \`concurrency\`). Serialize only when a
step needs a prior step's output. Synthesize all results back to the user.

Subagent retry policy: if a subagent fails or times out, retry ONCE with a tighter
spec — exact paths, expected output shape, and validation command. If still failing,
split the spec into smaller pieces, or escalate to \`oracle\` / \`reviewer\` for
diagnosis. Do not silently rerun the same broken task.

Acceptance policy — set the task’s \`acceptance\` explicitly whenever stricter than
the default is needed; do NOT override or hard-downgrade after the fact.
- \`none\` or \`attested\`: scout / researcher / reviewer / planner / oracle — recon,
  read-only, diagnosis, docs, or decision work. No changed-files or tests-added
  evidence is expected from these.
- \`checked\` / \`verified\`: worker ONLY when the task actually edits code AND
  you expect validation/test/build evidence (changed files + tests added/updated +
  commands run). Never ask a recon-only subagent for \`checked\` if it cannot
  produce that evidence — that’s a contract mismatch, not a child failure.
- If the user supplies an Acceptance Contract in the request, pass it through
  verbatim and ask the child to emit the matching \`acceptance-report\` fenced JSON
  alongside its inline summary.
`.trim();

const TODO_DIRECTIVE = `
## Phases: Understand → Todo → Delegate → Verify → Report.

Understand first. If the request is ambiguous, underspecified, or "done" is unclear,
STOP and ask the user with \`ask_user_question\` before doing anything else. Never
guess scope or intent.

Todo next. Once the task is clear, before your FIRST action (delegate or bash),
create a todo list with the \`todo\` tool (action: "create"), one item per phase.
The \`subagent\` and \`bash\` tools are gated until a todo list exists. Mark an item
in_progress before you start it and completed the moment it is done; keep exactly
one in_progress. IMPORTANT: do NOT batch a \`todo\` create/update together with a
\`subagent\` or \`bash\` call in the same tool-call batch — emit the todo first, end
the turn, then run the action on the next turn so the gate sees the snapshot. Use
\`todo update\` between phases to keep the list current.

A pure factual answer (one-line lookup with no code or state change) needs no todo;
otherwise the phases apply even when steps are tiny.
`.trim();

const BLOCK_REASON =
	"Blocked: orchestrator must not edit files directly (scheduler-first mode). Delegate " +
	"this change via the `subagent` tool to `worker`, " +
	"passing the exact file paths and spec. Run `/scheduler off` if you truly need to edit inline.";

const RECON_BLOCK_REASON =
	"Blocked: orchestrator must not inspect files directly (scheduler-first mode). Delegate " +
	"recon via the `subagent` tool to `scout` (codebase) or `researcher` (web/docs), then " +
	"synthesize their returned result. Run `/scheduler off` to bypass.";

const TODO_GATE_REASON =
	'Blocked: plan first. Create or update a todo with the `todo` tool (action: "create" / ' +
	'"update"), one item per step. Then end this assistant turn and retry the subagent or ' +
	'bash call in a SEPARATE next assistant turn — do NOT batch the todo and the ' +
	'subagent/bash call in the same tool-call batch. Run `/scheduler off` to bypass.';

const DELEGATION_RETRY_PROMPT =
	"Subagent failed. A contract mismatch (wrong acceptance level for the task type) is NOT a child failure — " +
	"retry with the task-appropriate acceptance: `none`/`attested` for recon/research/review/planning/oracle " +
	"work, `checked`/`verified` only for real code edits with validation/test evidence expected. " +
	"Also tighten the spec (exact paths, expected output, validation); split the task if still failing; " +
	"escalate to oracle/reviewer. If an Acceptance Contract was supplied, pass it through and ask for the " +
	"matching acceptance-report fenced JSON. Update todos and capture the failure.";

const BLOCKED_EDIT_TOOLS = new Set(["edit", "write", "morph_fastapply"]);
const BLOCKED_RECON_TOOLS = new Set(["read", "grep", "find", "ls"]);
// Whole recon/research tool families → delegate to scout (codebase) / researcher (web/docs).
// Includes all current/likely prefixed recon/doc/search tools (context-mode, warpgrep,
// gitnexus, tavily, firecrawl, context7). Keep BLOCKED_RECON_TOOLS above for unprefixed names.
const BLOCKED_RECON_PREFIXES = [
	"ctx_",
	"context_mode_ctx_",
	"context-mode_ctx_",
	"warpgrep_",
	"gitnexus_",
	"tavily_",
	"firecrawl_",
	"context7_",
];
// The orchestrator's only real action tools — gated until a todo list exists.
const TODO_GATED_TOOLS = new Set(["subagent", "bash"]);

// ---- subagent artifact read allowlist --------------------------------------
// When delegating to subagents, large raw output gets saved as an artifact file under
// `~/.pi/agent/sessions/<sid>/subagent-artifacts/...`. The orchestrator must be able to
// read exactly those files to verify worker output without breaching the recon block.
// Any other recon routes through scout/researcher as usual.
const SUBAGENT_ARTIFACT_ROOT = path.join(homedir(), ".pi", "agent", "sessions");
const SUBAGENT_ARTIFACT_SEGMENT = `${path.sep}subagent-artifacts${path.sep}`;

function extractReadPath(input: unknown): string | undefined {
	if (!input || typeof input !== "object") return undefined;
	const i = input as { path?: unknown; filePath?: unknown };
	const p = (i.path ?? i.filePath) as unknown;
	return typeof p === "string" && p.length > 0 ? p : undefined;
}

function isAllowedReadInput(input: unknown): boolean {
	try {
		const p = extractReadPath(input);
		if (!p) return false;
		const real = realpathSync(p);
		if (isSurfacedReadAllowed(real)) return true;
		const root = SUBAGENT_ARTIFACT_ROOT + path.sep;
		return real.startsWith(root) && real.includes(SUBAGENT_ARTIFACT_SEGMENT);
	} catch {
		return false;
	}
}

// ---- surfaced-file read allowlist ----------------------------------------
// Beyond subagent artifact files, the parent may read EXACT files surfaced by a
// successful scout/worker subagent output (realpath-locked, capped). Anything else
// (broad recon, listing directories) still routes through `scout`/`researcher`.
const SURFACED_READ_LIMIT = Math.max(1, Number(process.env.PI_ORCHESTRATOR_SURFACED_READ_LIMIT ?? "50") || 50);
const surfacedReadAllowlist = new Map<
	string,
	{ mtimeMs: number; size: number; dev: number; ino: number; ctimeMs: number; addedAt: number }
>();
// Surfaced-read roots gate. Free-form paths surfaced by successful subagent text only
// unlock reads inside these roots. Default: the orchestrator's cwd. Override via
// `PI_ORCHESTRATOR_SURFACED_READ_ROOTS` (paths separated by `path.delimiter`).
//
// Safety: roots that are too broad (filesystem root, homedir exactly, or top-level
// system dirs like /home, /Users, /tmp, /var, /etc) would silently unlock nearly
// every file on disk — reject those exact matches. cwd and narrower project subdirs
// remain valid. Falls back to cwd when env is unset; if cwd itself is unsafe, fail
// closed (empty root list — no surfaced reads unlock).

/** Roots we will never accept as a surfaced-read root: filesystem root, homedir
 * exactly, and the broad top-level system directories. Anything narrower passes. */
const SURFACED_READ_BLOCKED_EXACT = new Set<string>([
	path.sep, // `/`
	homedir(),
	"/home",
	"/Users",
	"/tmp",
	"/var",
	"/etc",
]);

/** Resolve (`path.resolve`, then `realpath` if possible), then reject any exact
 * match against `SURFACED_READ_BLOCKED_EXACT`. Returns `null` to drop the
 * candidate — callers must filter and fail closed if the result is empty. */
function normalizeSurfacedReadRoot(raw: string): string | null {
	if (typeof raw !== "string") return null;
	const trimmed = raw.trim();
	if (!trimmed) return null;
	let resolved: string;
	try {
		resolved = realpathSync(path.resolve(trimmed));
	} catch {
		resolved = path.resolve(trimmed);
	}
	if (SURFACED_READ_BLOCKED_EXACT.has(resolved)) return null;
	return resolved;
}

const SURFACED_READ_ROOTS: string[] = (() => {
	const envRaw = process.env.PI_ORCHESTRATOR_SURFACED_READ_ROOTS ?? "";
	const candidates =
		envRaw.length > 0
			? envRaw
				.split(path.delimiter)
				.map((s) => s.trim())
				.filter((s): s is string => s.length > 0)
			: [process.cwd()];
	const normalized = candidates
		.map(normalizeSurfacedReadRoot)
		.filter((s): s is string => !!s);
	if (normalized.length > 0) return normalized;
	// Default cwd also failed — re-run normalizer so a safe cwd still rescues us;
	// otherwise fail closed (zero roots → no surfaced reads unlock).
	const cwdFallback = normalizeSurfacedReadRoot(process.cwd());
	return cwdFallback ? [cwdFallback] : [];
})();

/** Exact root match OR strict child prefix `root + sep`. Prevents sibling-prefix bypass. */
function isUnderRoot(real: string, root: string): boolean {
	if (real === root) return true;
	return real.startsWith(root + path.sep);
}

/** True iff `real` sits under any configured surfaced-read root. */
function isUnderSurfacedReadRoot(real: string): boolean {
	for (const root of SURFACED_READ_ROOTS) {
		if (isUnderRoot(real, root)) return true;
	}
	return false;
}

/** Pull text out of mixed content shapes (string, array of {type:"text", object with text/content/output/result/message, …) without JSON.stringify-ing the whole event. Bounded at ~20k chars. */
function extractText(value: unknown): string {
	if (!value) return "";
	if (typeof value === "string") return value;
	if (Array.isArray(value)) {
		let out = "";
		for (const item of value) {
			out += extractText(item);
			if (out.length > 20_000) return out;
		}
		return out;
	}
	if (typeof value !== "object") return "";
	const obj = value as Record<string, unknown>;
	// Standard tool-result content shape: array of {type:"text", text:string}.
	if (Array.isArray(obj.content)) return extractText(obj.content);
	if (typeof obj.content === "string") return obj.content;
	for (const field of ["text", "output", "result", "message_text"]) {
		const v = obj[field];
		if (typeof v === "string") return v;
		if (v && typeof v === "object") return extractText(v);
	}
	if (obj.message && typeof obj.message === "object") return extractText(obj.message);
	// Last resort: recurse into common nested containers to find text.
	for (const field of ["parts", "data", "details", "args", "toolResult"]) {
		const v = obj[field];
		if (Array.isArray(v) || (v && typeof v === "object")) {
			const sub = extractText(v);
			if (sub) return sub;
		}
	}
	return "";
}

/** Absolute and tilde paths from backticks, bullet lines, and plain text. Conservative: file-like only. */
function extractSurfacedPaths(text: string): string[] {
	if (!text) return [];
	const out = new Set<string>();
	const cleaned = text.replace(/[`"'<>]/g, " ");
	const patterns: RegExp[] = [
		// backtick-quoted paths
		/`([^`\n]+)`/g,
		// bullet lines "- /path/to/file"
		/(?:^|\n)\s*(?:[-*]\s+|\d+\.\s+)([^\n]+)/g,
		// absolute paths in /home, /Users, /tmp, /var, /etc, /opt, /srv, /root
		/(?:^|\s)(\/(?:home|Users|tmp|var|etc|opt|srv|root)\/[^\s,;:()'"\]]+)/g,
		// any other /-prefixed absolute path
		/(?:^|\s)(\/[a-zA-Z][a-zA-Z0-9_.\-/]*)/g,
		// ~/... paths
		/(?:^|\s)(~\/[^\s,;:()'"\]]+|~[a-zA-Z0-9_.\-/]+)/g,
	];
	// Strip trailing punctuation left behind by bullet-line greediness.
	const TRAILING_JUNK = /[,.;:!?)\]}"'\u2014\u2013]+\s*$/;
	for (const re of patterns) {
		let m: RegExpExecArray | null;
		while ((m = re.exec(cleaned)) !== null) {
			let raw = (m[1] ?? "").trim().replace(TRAILING_JUNK, "");
			if (looksLikeFilePath(raw)) out.add(raw);
			if (out.size > SURFACED_READ_LIMIT * 4) break;
		}
	}
	return [...out];
}

/** Conservative file-path filter: must look like /path/something or ~ unless it ends with a file extension. */
function looksLikeFilePath(p: string): boolean {
	if (!p || p.length < 3) return false;
	// reject obvious non-paths
	if (/^(?:https?|file):/.test(p)) return false;
	const hasExt = /\.[a-zA-Z0-9]{1,8}$/.test(p);
	if (p.startsWith("~")) return p.includes("/") || hasExt;
	if (p.startsWith("/")) {
		if (p.startsWith("/home/") || p.startsWith("/Users/")) return true;
		return hasExt;
	}
	return false;
}

/** Add a surfaced path to the allowlist (expand ~, realpath, lock mtime). Enforce cap. */
function rememberSurfacedRead(rawPath: string): void {
	try {
		let p = rawPath.trim();
		if (!p) return;
		if (p.startsWith("~")) {
			const home = homedir();
			p = p === "~" ? home : path.join(home, p.slice(2));
		}
		const real = realpathSync(p);
		// Free-form paths surfaced from successful subagent text must sit under a
		// configured surfaced-read root — env can add roots if needed. Drop anything else.
		if (!isUnderSurfacedReadRoot(real)) return;
		// Stat MUST succeed and target MUST be a regular file. Path-only entries with a
		// zeroed mtime previously unlocked a file forever — require a real mtime.
		let st: import("node:fs").Stats;
		try {
			st = statSync(real);
		} catch {
			return;
		}
		if (!st.isFile()) return;
		surfacedReadAllowlist.set(real, {
			mtimeMs: st.mtimeMs,
			size: st.size,
			dev: st.dev,
			ino: st.ino,
			ctimeMs: st.ctimeMs,
			addedAt: Date.now(),
		});
		if (surfacedReadAllowlist.size > SURFACED_READ_LIMIT) {
			let oldestKey: string | undefined;
			let oldestTs = Infinity;
			for (const [k, v] of surfacedReadAllowlist) {
				if (v.addedAt < oldestTs) {
					oldestTs = v.addedAt;
					oldestKey = k;
				}
			}
			if (oldestKey) surfacedReadAllowlist.delete(oldestKey);
		}
	} catch {
		/* swallow — surfaced path is best-effort */
	}
}

/** True iff the realpath was surfaced by a successful subagent AND the on-disk
 * file still matches the recorded identity (mtime + ctime + size + dev + ino).
 * Any mismatch (truncate, replace-in-place, move-to-different-inode) un-locks the
 * path — caller must re-surface before reading again. */
function isSurfacedReadAllowed(realPath: string): boolean {
	const entry = surfacedReadAllowlist.get(realPath);
	if (!entry) return false;
	let st: import("node:fs").Stats;
	try {
		st = statSync(realPath);
	} catch {
		return false;
	}
	if (!st.isFile()) return false;
	return (
		st.mtimeMs === entry.mtimeMs &&
		st.ctimeMs === entry.ctimeMs &&
		st.size === entry.size &&
		st.dev === entry.dev &&
		st.ino === entry.ino
	);
}

/** Pull text from a successful subagent tool_result and remember any surfaced paths. */
function recordSurfacedReadsFromSubagent(event: unknown): void {
	const e = event as Record<string, unknown> | null;
	if (!e) return;
	const text = extractText([e.result, e.output, e.content, e.message, e.toolResult, e.details]);
	if (!text) return;
	for (const p of extractSurfacedPaths(text)) rememberSurfacedRead(p);
}

// ---- strict bash mode -----------------------------------------------------
// Bash is allowed ONLY for orchestration glue. No file reads, edits, network,
// or shell escapes from the parent's bash tool. All file/network/docs work
// routes through delegated subagents.

const BASH_ALLOWED_ROOTS = new Set([
	"git",
	"npm",
	"pnpm",
	"yarn",
	"bun",
	"npx",
	"bunx",
	"make",
	"pytest",
	"go",
	"cargo",
]);
// Defense in depth: restrict `git` to orchestration-only subcommands. Anything else
// (exec, config, mv-unused flags) routes through a delegated subagent.
const BASH_ALLOWED_GIT_SUBCMDS = new Set([
	"status",
	"diff",
	"log",
	"show",
	"branch",
	"rev-parse",
	"merge-base",
	"ls-files",
	"add",
	"commit",
	"restore",
	"checkout",
	"stash",
	"fetch",
	"pull",
	"push",
]);
// Restrict `npx` / `bunx` to well-known build/test/lint/typecheck runners — any other
// package invocation routes through a delegated subagent.
const BASH_ALLOWED_RUNNERS = new Set([
	"tsc",
	"eslint",
	"vitest",
	"jest",
	"biome",
	"next",
	"turbo",
	"nx",
	"prettier",
]);
// Reject ANY shell metachar / separator / substitution anywhere in the command —
// must run BEFORE the root allowlist so chaining/escapes can never bypass it.
// Conservative: blocks `;`, `&`, `|`, `<`, `>`, newline/CR, command substitution
// via `$(...)` and backticks, `${...}`, parens (`(...)`), and backslashes. Plain
// single commands with quoted flags/args pass; anything that could escape or chain
// fails closed.
const BASH_SHELL_META_PATTERN = /[;&|<>`\\\n\r]|\$\{|\$\(|\(|\)/;
// Match deny tokens as standalone words OR as redirection/operators anywhere.
const BASH_DENY_PATTERN =
	/(?:\b(?:cat|sed|awk|head|tail|tee|less|more|vi|vim|nvim|nano|emacs|curl|wget|dd|cp|mv|rm|chmod|chown|mkdir|rmdir|touch|ssh|scp|rsync|sudo|xargs|node|python|python3|perl|ruby|php|sh|bash|zsh|fish)\b|>>?|<<?|\|)/;

/** Validate a single plain command, or the right-hand side of `cd DIR && CMD`. */
function plainBashCommandAllowed(command: string): boolean {
	let s = command.trim();
	if (!s) return false;
	// Strip leading env assignments (FOO=bar BAZ=qux npm test).
	s = s.replace(/^(?:[A-Za-z_][A-Za-z0-9_]*=[^\s]+\s*)+/, "").trim();
	if (!s) return false;
	// Hard-reject any shell meta / separator / substitution anywhere.
	if (BASH_SHELL_META_PATTERN.test(s)) return false;
	// Deny anywhere: shell escapes / read / edit / network tokens or redirections/pipes.
	if (BASH_DENY_PATTERN.test(s)) return false;
	const parts = s.split(/\s+/);
	const first = parts[0];
	if (!first || !BASH_ALLOWED_ROOTS.has(first)) return false;
	// Defense in depth: limit `git` to orchestration subcommands.
	if (first === "git") {
		const sub = parts[1];
		if (!sub || !BASH_ALLOWED_GIT_SUBCMDS.has(sub)) return false;
	}
	// Defense in depth: limit `npx` / `bunx` to known runners (tsc, eslint, vitest, …).
	if (first === "npx" || first === "bunx") {
		if (!runnerAllowed(parts)) return false;
	}
	return true;
}

/** True iff `tokens` is an `npx`/`bunx <runner>` invocation, skipping leading flags. */
function runnerAllowed(tokens: string[]): boolean {
	const runners = ["npx", "bunx"];
	const first = tokens[0];
	if (!first || !runners.includes(first)) return false;
	let i = 1;
	while (i < tokens.length && tokens[i].startsWith("-")) i++;
	const pkg = tokens[i];
	if (!pkg) return false;
	// Handle scoped packages (`@scope/pkg` → `pkg`) and pinned versions (`eslint@9` → `eslint@9`).
	const base = pkg.split("/").pop() ?? pkg;
	return BASH_ALLOWED_RUNNERS.has(base);
}

/** True iff `input.command` is an allowlisted bash invocation. Supports exactly `cd DIR && CMD`. */
function bashCommandAllowed(input: unknown): boolean {
	const cmd = (input as { command?: unknown } | null)?.command;
	if (typeof cmd !== "string") return false;
	const trimmed = cmd.trim();
	if (!trimmed) return false;
	// Exactly one `&&`: only `cd DIR && COMMAND` is permitted, so the parent can pin cwd first.
	if (trimmed.includes("&&")) {
		const parts = trimmed.split("&&");
		if (parts.length !== 2) return false;
		const left = parts[0].trim();
		if (!/^cd\s+\S+$/.test(left)) return false;
		const cdPath = left.replace(/^cd\s+/, "").trim();
		if (cdPath.startsWith("-")) return false;
		if (/[;|<>`\\\n\r$()]/.test(cdPath)) return false;
		return plainBashCommandAllowed(parts[1].trim());
	}
	return plainBashCommandAllowed(trimmed);
}

/** Terse block reason for non-allowlisted bash invocations. */
function bashBlockReason(command?: string): string {
	const head = typeof command === "string" && command.trim() ? ` Tried: \`${command.trim().split(/\s+/)[0] ?? ""}\`.` : "";
	return (
		"Blocked: bash from the orchestrator is restricted to orchestration glue (git, " +
		"npm/pnpm/yarn/bun/npx/bunx, make, pytest, go, cargo). Use a SINGLE plain command, " +
		"or `cd DIR && COMMAND` to pin cwd first — no other chaining (&& / || / ;), " +
		"no pipes, redirects, or substitutions ($() / backticks / ${}). For npx/bunx, only " +
		"known runners are allowed (tsc, eslint, vitest, jest, biome, next, turbo, nx, " +
		"prettier). For git, only orchestration subcommands are allowed (status, diff, log, show, " +
		"branch, rev-parse, merge-base, ls-files, add, commit, restore, checkout, stash, " +
		"fetch, pull, push). Delegate file inspection, edits, network, and docs to " +
		"scout / researcher / worker via `subagent`." + head
	);
}

// ---- subagent inline summary ----------------------------------------------
// Ask every delegated subagent to return a concise inline summary (outcome, files
// touched, validation, blockers) in its final response. Save raw output to an
// artifact file only when it's too large; include the artifact path. Marker is
// idempotent — prevents double-appends on nested/array call shapes.
const SUBAGENT_INLINE_SUMMARY_MARKER = "[orchestrator:inline-summary]";
const SUBAGENT_INLINE_SUMMARY_INSTRUCTION = `${SUBAGENT_INLINE_SUMMARY_MARKER} Return a concise inline summary in final response: outcome, files touched, validation, blockers. For scout/recon tasks, include relevant snippets/line numbers inline; avoid path-only answers. If the task contains an Acceptance Contract, include the matching acceptance-report fenced JSON too. Save artifacts only for large raw output and include artifact path.`;

// Default acceptance policy: "none" avoids brittle auto-inferred acceptance-rejection
// failures across diverse models. Override via PI_ORCHESTRATOR_SUBAGENT_ACCEPTANCE
// (e.g. "auto") or per-call by setting `acceptance` explicitly on a task-holder.
const SUBAGENT_DEFAULT_ACCEPTANCE = process.env.PI_ORCHESTRATOR_SUBAGENT_ACCEPTANCE ?? "none";
// Floor applied to the env-derived subagent timeout default — prevents premature
// 0/30s cutoffs on small models or broad tasks.
const SUBAGENT_TIMEOUT_FLOOR_MS = 60_000;
// Default subagent timeout. Override via PI_ORCHESTRATOR_SUBAGENT_TIMEOUT_MS
// (milliseconds). The env-derived value is floored at SUBAGENT_TIMEOUT_FLOOR_MS.
// Explicit caller-supplied `timeoutMs` / `maxRuntimeMs` are always respected —
// never clamped. Top-level only.
const SUBAGENT_DEFAULT_TIMEOUT_MS = Math.max(
	SUBAGENT_TIMEOUT_FLOOR_MS,
	Number(process.env.PI_ORCHESTRATOR_SUBAGENT_TIMEOUT_MS ?? "600000") || 600000,
);

/** Set `record.acceptance` to the env default only when not already explicitly set. */
function applyAcceptanceDefault(record: Record<string, unknown>): void {
	if (!("acceptance" in record)) record.acceptance = SUBAGENT_DEFAULT_ACCEPTANCE;
}

/** Apply default subagent timeout to top-level input only. Does NOT touch inner task
 * holders. Sets `timeoutMs` to the default only when BOTH `timeoutMs` and
 * `maxRuntimeMs` are absent; any explicit caller value is respected — never clamped. */
function applySubagentTimeoutDefaults(input: unknown): void {
	if (!input || typeof input !== "object") return;
	const record = input as Record<string, unknown>;
	const hasTimeout = typeof record.timeoutMs === "number";
	const hasMax = typeof record.maxRuntimeMs === "number";
	if (!hasTimeout && !hasMax) record.timeoutMs = SUBAGENT_DEFAULT_TIMEOUT_MS;
}

function appendInlineSummaryInstruction(task: string): string {
	return task.includes(SUBAGENT_INLINE_SUMMARY_MARKER) ? task : `${task}\n\n${SUBAGENT_INLINE_SUMMARY_INSTRUCTION}`;
}

function decorateTaskHolder(value: unknown): void {
	if (!value || typeof value !== "object") return;
	const record = value as Record<string, unknown>;
	if (typeof record.task === "string") record.task = appendInlineSummaryInstruction(record.task);
	applyAcceptanceDefault(record);
}

function decorateSubagentInput(input: unknown): void {
	decorateTaskHolder(input);
	if (!input || typeof input !== "object") return;
	const record = input as Record<string, unknown>;
	if (Array.isArray(record.tasks)) for (const item of record.tasks) decorateTaskHolder(item);
	if (Array.isArray(record.chain)) {
		for (const step of record.chain) {
			decorateTaskHolder(step);
			if (!step || typeof step !== "object") continue;
			const stepRecord = step as Record<string, unknown>;
			const parallel = stepRecord.parallel;
			if (Array.isArray(parallel)) for (const item of parallel) decorateTaskHolder(item);
			else decorateTaskHolder(parallel);
		}
	}
	// Top-level only: default subagent timeout when both timeoutMs and maxRuntimeMs absent.
	applySubagentTimeoutDefaults(input);
}

// ---- pure helpers ----------------------------------------------------------

type TodoTask = {
	id?: string | number;
	status?: string;
	subject?: string;
	title?: string;
	content?: string;
	description?: string;
};

/** Walk the branch backwards to the latest `todo` toolResult snapshot's tasks. */
function latestTodoTasks(entries: unknown[]): TodoTask[] | undefined {
	for (let i = entries.length - 1; i >= 0; i--) {
		const e = entries[i] as {
			type?: string;
			message?: { role?: string; toolName?: string; details?: { tasks?: TodoTask[]; nextId?: number } };
		};
		if (e?.type !== "message") continue;
		const m = e.message;
		// rpiv-todo snapshot discriminator: last `todo` toolResult on the branch wins.
		if (m?.role !== "toolResult" || m.toolName !== "todo") continue;
		if (Array.isArray(m.details?.tasks)) return m.details!.tasks;
	}
	return undefined;
}

/** Latest todo snapshot → count of pending/in_progress items. */
function incompleteTodoCount(entries: unknown[]): number {
	const tasks = latestTodoTasks(entries);
	if (!tasks) return 0;
	return incompleteTasks(tasks).length;
}

/** Normalize status to a lowercase string (`"pending"`, `"in_progress"`, `"completed"`, …). */
function taskStatus(task: TodoTask): string {
	return ((task?.status ?? "") as string).toString().toLowerCase();
}

/** Concise label for a todo item: id + first non-empty subject/title/content/description. Max ~100 chars. */
function taskLabel(task: TodoTask): string {
	const candidates = [task?.subject, task?.title, task?.content, task?.description];
	const picked = candidates.find(
		(c): c is string => typeof c === "string" && c.trim().length > 0,
	);
	const base = (picked ?? (task?.id !== undefined ? String(task.id) : "(unnamed)")).trim();
	return base.length > 100 ? `${base.slice(0, 97)}…` : base;
}

/** Tasks still pending or in_progress (normalized, so any case works). */
function incompleteTasks(tasks: TodoTask[]): TodoTask[] {
	return tasks.filter((t) => {
		const s = taskStatus(t);
		return s === "pending" || s === "in_progress";
	});
}

/** Stable signature over incomplete task labels + status — same set + same ordering = same sig. */
function todoSnapshotSignature(tasks: TodoTask[]): string {
	return incompleteTasks(tasks).map((t) => `${taskLabel(t)}@${taskStatus(t)}`).join("|");
}

/** Build a stateful auto-continue prompt from the current todo snapshot. */
function buildContinuePrompt(tasks: TodoTask[], repeated: boolean): string {
	const remaining = incompleteTasks(tasks);
	const inProgress = remaining.find((t) => taskStatus(t) === "in_progress");
	const pending = remaining.filter((t) => taskStatus(t) === "pending");
	const lines: string[] = [];
	if (inProgress) {
		lines.push(`Current task (in_progress): ${taskLabel(inProgress)}.`);
	}
	if (pending.length > 0) {
		lines.push("Next task(s):");
		for (const t of pending.slice(0, 3)) lines.push(`- ${taskLabel(t)}`);
	}
	lines.push(
		"If work has already returned for the current task, do NOT re-run or re-check it. " +
			"Update its todo status to 'completed' (or blocker) and move to the next.",
	);
	lines.push(
		"Do not call todo/list repeatedly. Make ONE todo update, then delegate/verify/report. " +
			"Avoid extra recon loops.",
	);
	if (repeated) {
		lines.push(
			"Same todo snapshot as the last auto-continue. Stop looping: either mark the current " +
				"todo completed, create a blocker, or ask the user. Do not redo recon.",
		);
	}
	return lines.join(" ");
}

/** Has the model created a todo list with at least one item? */
function hasTodoList(entries: unknown[]): boolean {
	const tasks = latestTodoTasks(entries);
	return !!tasks && tasks.length > 0;
}

/** Concatenated text of the last assistant message in a message list. */
function lastAssistantText(messages: unknown[]): string {
	for (let i = messages.length - 1; i >= 0; i--) {
		const m = messages[i] as { role?: string; content?: unknown };
		if (m?.role !== "assistant") continue;
		const c = m.content;
		if (typeof c === "string") return c;
		if (Array.isArray(c)) {
			return c
				.filter((p): p is { type: string; text: string } => !!p && (p as { type?: string }).type === "text")
				.map((p) => p.text)
				.join(" ");
		}
		return "";
	}
	return "";
}

/** Did the agent end on a question? (don't auto-continue when it's awaiting the user) */
function isQuestionText(text: string): boolean {
	return (text || "").trim().endsWith("?");
}

// ---------------------------------------------------------------------------

export default function (pi: ExtensionAPI) {
	if (IS_CHILD) return; // never enforce/continue inside spawned subagents

	let enabled = process.env.PI_SCHEDULER_OFF !== "1";

	pi.on("before_agent_start", (event) => {
		const parts = [event.systemPrompt];
		if (enabled) parts.push(TODO_DIRECTIVE, DIRECTIVE);
		return { systemPrompt: parts.join("\n\n") };
	});

	pi.on("tool_call", (event, ctx) => {
		if (!enabled) return;
		// subagent inline summary mutation: ask workers to return a concise inline
		// summary by default; save raw output to the artifact file only when it's
		// too large to return directly. Idempotent — marker prevents double-appends.
		if (event.toolName === "subagent") decorateSubagentInput(event.input);
		// read bypass: orchestrator may read subagent-artifact files saved under
		// ~/.pi/agent/sessions/<sid>/subagent-artifacts/ to verify worker output.
		if (event.toolName === "read" && isAllowedReadInput(event.input)) return;
		if (BLOCKED_EDIT_TOOLS.has(event.toolName)) return { block: true, reason: BLOCK_REASON };
		if (BLOCKED_RECON_TOOLS.has(event.toolName)) return { block: true, reason: RECON_BLOCK_REASON };
		if (BLOCKED_RECON_PREFIXES.some((p) => event.toolName.startsWith(p))) return { block: true, reason: RECON_BLOCK_REASON };
		// plan-first: the model must create a todo list before any real action (delegate or bash).
		if (TODO_GATED_TOOLS.has(event.toolName)) {
			let has = true; // fail open — never wedge work on a read error
			try {
				has = hasTodoList(ctx.sessionManager.getBranch());
			} catch {
				has = true;
			}
			if (!has) return { block: true, reason: TODO_GATE_REASON };
			// Strict bash: allowlist roots only, deny obvious read/edit/network/shell-escape tokens.
			if (event.toolName === "bash" && !bashCommandAllowed(event.input)) {
				const cmd = (event.input as { command?: unknown } | null)?.command;
				return { block: true, reason: bashBlockReason(typeof cmd === "string" ? cmd : undefined) };
			}
		}
		return;
	});

	// Subagent failure nudge: when a delegated subagent returns isError, notify once so the
	// orchestrator applies the retry policy (tighter spec, split, or escalate) instead of
	// silently repeating the same broken call. Prompt guidance is the primary mechanism;
	// this hook is a single backstop reminder.
	pi.on("tool_result", (event, ctx) => {
		if (!enabled) return;
		if (event.toolName !== "subagent") return;
		if (!event.isError) recordSurfacedReadsFromSubagent(event);
		if (!event.isError) return;
		ctx.ui.notify(
			"Subagent failed. Retry policy: tighten the spec (exact paths, expected output, " +
				"validation command); split the task if broad; escalate to oracle/reviewer if it persists.",
			"warning",
		);
		void pi.sendUserMessage(DELEGATION_RETRY_PROMPT, { deliverAs: "followUp" });
	});

	pi.registerCommand("scheduler", {
		description:
			"Toggle scheduler-first mode (blocks edit/write/morph + read/grep/find/ls; gates subagent+bash on a todo)",
		handler: async (args, ctx) => {
			const arg = (args || "").trim().toLowerCase();
			if (arg === "on") enabled = true;
			else if (arg === "off") enabled = false;
			else enabled = !enabled;
			ctx.ui.notify(
				enabled
					? "Scheduler-first ON — delegate everything; recon + edit tools blocked, subagent + bash gated on a todo."
					: "Scheduler-first OFF — direct read/edit allowed.",
				"info",
			);
		},
	});

	// ---- auto-continue (idle → resume incomplete todos) --------------------

	let acEnabled = process.env.PI_AUTOCONTINUE_OFF !== "1";
	const MAX = Number(process.env.PI_AUTOCONTINUE_MAX) || 5;
	const COOLDOWN = Number(process.env.PI_AUTOCONTINUE_COOLDOWN_MS) || 4000;

	let consecutive = 0;
	let cappedNotified = false;
	let pendingTimer: ReturnType<typeof setTimeout> | null = null;
	let lastContinueSignature = "";
	let repeatedContinueCount = 0;
	const STALE_MAX = Math.max(
		0,
		Number(process.env.PI_AUTOCONTINUE_STALE_MAX ?? "1") || 0,
	);

	const cancelPending = () => {
		if (pendingTimer) {
			clearTimeout(pendingTimer);
			pendingTimer = null;
		}
	};

	pi.on("agent_end", (event, ctx) => {
		if (!acEnabled) return;
		if (pendingTimer) return; // already armed

		// Capture current todo snapshot for the closure below; reset state if no work left.
		let remaining: TodoTask[] = [];
		try {
			const tasks = latestTodoTasks(ctx.sessionManager.getBranch());
			remaining = tasks ? incompleteTasks(tasks) : [];
		} catch {
			return;
		}
		if (remaining.length === 0) {
			consecutive = 0; // todos done — reset the loop
			cappedNotified = false;
			lastContinueSignature = "";
			repeatedContinueCount = 0;
			return;
		}

		// Don't barge in if the agent ended by asking the user something.
		if (isQuestionText(lastAssistantText(event.messages as unknown[]))) return;

		const initialRemainingCount = remaining.length;
		if (consecutive >= MAX) {
			if (!cappedNotified) {
				cappedNotified = true;
				ctx.ui.notify(
					`Auto-continue paused after ${MAX} rounds — ${initialRemainingCount} todo(s) left. Type to resume, or /autocontinue off.`,
					"warning",
				);
			}
			return;
		}

		ctx.ui.notify(
			`Auto-continue: ${initialRemainingCount} todo(s) left — resuming in ${Math.round(COOLDOWN / 1000)}s (type to cancel)`,
			"info",
		);
		pendingTimer = setTimeout(() => {
			pendingTimer = null;
			if (!acEnabled) return;
			// Re-read branch: tasks may have completed during cooldown. Stale auto-continue guard.
			let stillRemaining: TodoTask[] = [];
			try {
				const tasks = latestTodoTasks(ctx.sessionManager.getBranch());
				stillRemaining = tasks ? incompleteTasks(tasks) : [];
			} catch {
				return;
			}
			if (stillRemaining.length === 0) {
				consecutive = 0;
				cappedNotified = false;
				lastContinueSignature = "";
				repeatedContinueCount = 0;
				return;
			}
			// Detect same snapshot across fires → model is repeating the same nudge without
			// updating todos. After STALE_MAX repeats, pause instead of looping.
			const signature = todoSnapshotSignature(stillRemaining);
			if (signature && signature === lastContinueSignature) {
				repeatedContinueCount++;
			} else {
				repeatedContinueCount = 0;
				lastContinueSignature = signature;
			}
			if (repeatedContinueCount > STALE_MAX) {
				consecutive = 0;
				cappedNotified = false;
				lastContinueSignature = "";
				repeatedContinueCount = 0;
				cancelPending();
				ctx.ui.notify(
					"Auto-continue paused: todo snapshot unchanged. Update current todo or ask user.",
					"warning",
				);
				return;
			}
			consecutive++;
			void pi.sendUserMessage(
				buildContinuePrompt(stillRemaining, repeatedContinueCount > 0),
				{ deliverAs: "followUp" },
			);
		}, COOLDOWN);
	});

	// Real user input (not our own injection) cancels a pending resume and resets the loop.
	pi.on("input", (event) => {
		if (event.source === "extension") return; // our continuation — ignore
		consecutive = 0;
		cappedNotified = false;
		lastContinueSignature = "";
		repeatedContinueCount = 0;
		cancelPending();
	});

	pi.registerCommand("autocontinue", {
		description: "Toggle auto-continue: on idle with incomplete todos, re-prompt to keep working (OMOS-style)",
		handler: async (args, ctx) => {
			const arg = (args || "").trim().toLowerCase();
			if (arg === "on") acEnabled = true;
			else if (arg === "off") acEnabled = false;
			else acEnabled = !acEnabled;
			if (!acEnabled) cancelPending();
			consecutive = 0;
			cappedNotified = false;
			ctx.ui.notify(
				acEnabled
					? `Auto-continue ON — resumes incomplete todos when idle (max ${MAX} rounds).`
					: "Auto-continue OFF.",
				"info",
			);
		},
	});
}
