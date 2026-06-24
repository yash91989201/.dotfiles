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
inspect files yourself. For anything beyond a short factual answer you MUST hand the
work to a subagent via the \`subagent\` tool.

Hard rules (enforced — these tools are blocked for you):
- Do NOT call \`read\`, \`grep\`, \`find\`, or \`ls\`. Delegate recon to \`scout\`
  (codebase) or \`researcher\` (web/docs) and synthesize their returned result.
- Do NOT call \`edit\`, \`write\`, or \`morph_fastapply\`. Delegate edits to \`worker\`
  (or \`fixer\` for a concrete spec) with exact paths and a spec.
- \`bash\` is allowed ONLY for orchestration glue (git, running tests). Never use it to
  read or edit files — delegate that.

Route by intent (call \`subagent\`):
- Recon / unfamiliar code → scout
- External docs, APIs, web → researcher
- Plan a multi-step change → planner
- Implement code → worker (concrete spec → fixer)
- Review a diff or plan → reviewer
- Backend / API / auth / schema design → backend-architect
- DB schema, queries, migrations → database-engineer
- React / UI components → frontend-specialist (visual judgment → designer)
- Refactor / tech debt → refactoring-expert
- Docker / RabbitMQ → docker-expert / rabbitmq-expert
- Hard call or decision drift → oracle
- Image / screenshot → vision

Parallelize aggressively. When steps are INDEPENDENT — e.g. recon the codebase AND
research external docs at once, or fan out several scoped implementations — issue ONE
\`subagent\` call with a \`tasks\` array (\`tasks: [{ agent, task }, …]\`, optional
\`concurrency\`); they run concurrently. Serialize only when a step genuinely needs a
prior step's output. Synthesize all results back to the user.
`.trim();

const TODO_DIRECTIVE = `
## Understand, then plan (todo)

FIRST understand the request. If the requirement is ambiguous, underspecified, or you are
not confident what "done" looks like, STOP and ask the user to clarify with
\`ask_user_question\` before doing anything else — never guess scope or assume intent.

Once the requirement is clear: before your FIRST action on a task — delegating OR running
bash — create a todo list with the \`todo\` tool (action: "create"), one item per step.
The \`subagent\` and \`bash\` tools are blocked until a todo list exists. Mark an item
in_progress before you start it and completed the moment it's done; keep exactly one
in_progress. A pure factual answer needs no todo.
`.trim();

const BLOCK_REASON =
	"Blocked: orchestrator must not edit files directly (scheduler-first mode). Delegate " +
	"this change via the `subagent` tool to `worker` (or `fixer` for a concrete spec), " +
	"passing the exact file paths and spec. Run `/scheduler off` if you truly need to edit inline.";

const RECON_BLOCK_REASON =
	"Blocked: orchestrator must not inspect files directly (scheduler-first mode). Delegate " +
	"recon via the `subagent` tool to `scout` (codebase) or `researcher` (web/docs), then " +
	"synthesize their returned result. Run `/scheduler off` to bypass.";

const TODO_GATE_REASON =
	'Blocked: plan first. Create a todo list with the `todo` tool (action: "create"), one ' +
	"item per step, before delegating or running bash. Run `/scheduler off` to bypass.";

const CONTINUE_PROMPT =
	"Continue working through your todo list. Mark each item in_progress before you start it " +
	"and completed when it's done. If every item is finished, say so briefly and stop.";

const BLOCKED_EDIT_TOOLS = new Set(["edit", "write", "morph_fastapply"]);
const BLOCKED_RECON_TOOLS = new Set(["read", "grep", "find", "ls"]);
// The orchestrator's only real action tools — gated until a todo list exists.
const TODO_GATED_TOOLS = new Set(["subagent", "bash"]);

// ---- pure helpers ----------------------------------------------------------

type TodoTask = { status?: string };

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
	return tasks.filter((t) => t?.status === "pending" || t?.status === "in_progress").length;
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
		if (BLOCKED_EDIT_TOOLS.has(event.toolName)) return { block: true, reason: BLOCK_REASON };
		if (BLOCKED_RECON_TOOLS.has(event.toolName)) return { block: true, reason: RECON_BLOCK_REASON };
		// plan-first: the model must create a todo list before any real action (delegate or bash).
		if (TODO_GATED_TOOLS.has(event.toolName)) {
			let has = true; // fail open — never wedge work on a read error
			try {
				has = hasTodoList(ctx.sessionManager.getBranch());
			} catch {
				has = true;
			}
			if (!has) return { block: true, reason: TODO_GATE_REASON };
		}
		return;
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

	const cancelPending = () => {
		if (pendingTimer) {
			clearTimeout(pendingTimer);
			pendingTimer = null;
		}
	};

	pi.on("agent_end", (event, ctx) => {
		if (!acEnabled) return;
		if (pendingTimer) return; // already armed

		let incomplete = 0;
		try {
			incomplete = incompleteTodoCount(ctx.sessionManager.getBranch());
		} catch {
			return;
		}
		if (incomplete === 0) {
			consecutive = 0; // todos done — reset the loop
			cappedNotified = false;
			return;
		}

		// Don't barge in if the agent ended by asking the user something.
		if (isQuestionText(lastAssistantText(event.messages as unknown[]))) return;

		if (consecutive >= MAX) {
			if (!cappedNotified) {
				cappedNotified = true;
				ctx.ui.notify(
					`Auto-continue paused after ${MAX} rounds — ${incomplete} todo(s) left. Type to resume, or /autocontinue off.`,
					"warning",
				);
			}
			return;
		}

		ctx.ui.notify(
			`Auto-continue: ${incomplete} todo(s) left — resuming in ${Math.round(COOLDOWN / 1000)}s (type to cancel)`,
			"info",
		);
		pendingTimer = setTimeout(() => {
			pendingTimer = null;
			if (!acEnabled) return;
			consecutive++;
			void pi.sendUserMessage(CONTINUE_PROMPT, { deliverAs: "followUp" });
		}, COOLDOWN);
	});

	// Real user input (not our own injection) cancels a pending resume and resets the loop.
	pi.on("input", (event) => {
		if (event.source === "extension") return; // our continuation — ignore
		consecutive = 0;
		cappedNotified = false;
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
