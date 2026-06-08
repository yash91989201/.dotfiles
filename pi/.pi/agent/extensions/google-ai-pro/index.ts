import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import {
	calculateCost,
	createAssistantMessageEventStream,
	type Api,
	type AssistantMessage,
	type AssistantMessageEventStream,
	type Context,
	type ImageContent,
	type Message,
	type Model,
	type OAuthCredentials,
	type OAuthLoginCallbacks,
	type SimpleStreamOptions,
	type StopReason,
	type TextContent,
	type ThinkingContent,
	type Tool,
	type ToolCall,
} from "@earendil-works/pi-ai";
import * as fs from "node:fs";
import * as path from "node:path";

const PROVIDER = "google-ai-pro";
const API = "google-ai-pro-code-assist";

// Load OAuth credentials from auth.json (not checked into git)
const AUTH_JSON_PATH = path.join(__dirname, "auth.json");
let OAUTH_CLIENT_ID = "";
let OAUTH_CLIENT_SECRET = "";

function loadAuthConfig(): void {
	try {
		if (!fs.existsSync(AUTH_JSON_PATH)) {
			throw new Error(`auth.json not found at ${AUTH_JSON_PATH}`);
		}
		const raw = fs.readFileSync(AUTH_JSON_PATH, "utf-8");
		const auth = JSON.parse(raw);
		if (!auth.oauthClientId || !auth.oauthClientSecret) {
			throw new Error("auth.json must contain oauthClientId and oauthClientSecret");
		}
		if (isPlaceholderCredential(auth.oauthClientId) || isPlaceholderCredential(auth.oauthClientSecret)) {
			throw new Error(
				"auth.json still contains placeholder OAuth credentials. " +
				"Replace YOUR_CLIENT_ID/YOUR_CLIENT_SECRET with the Gemini CLI Code Assist OAuth client credentials."
			);
		}
		if (!String(auth.oauthClientId).endsWith(".apps.googleusercontent.com")) {
			throw new Error("auth.json oauthClientId does not look like a Google OAuth client ID");
		}
		OAUTH_CLIENT_ID = auth.oauthClientId;
		OAUTH_CLIENT_SECRET = auth.oauthClientSecret;
	} catch (error) {
		throw new Error(
			`Failed to load auth.json for google-ai-pro extension. ` +
			`Create ${AUTH_JSON_PATH} with oauthClientId and oauthClientSecret. ` +
			`See README.md for details. Error: ${error instanceof Error ? error.message : String(error)}`
		);
	}
}

function isPlaceholderCredential(value: unknown): boolean {
	return typeof value === "string" && /YOUR_CLIENT|REPLACE|TODO|<.*>/i.test(value);
}

loadAuthConfig();

const CODE_ASSIST_ENDPOINT = process.env.CODE_ASSIST_ENDPOINT ?? "https://cloudcode-pa.googleapis.com";
const CODE_ASSIST_API_VERSION = process.env.CODE_ASSIST_API_VERSION ?? "v1internal";
const CODE_ASSIST_BASE_URL = `${CODE_ASSIST_ENDPOINT}/${CODE_ASSIST_API_VERSION}`;

// Public OAuth client used by the official Gemini CLI Code Assist login flow.
const OAUTH_SCOPE = [
	"https://www.googleapis.com/auth/cloud-platform",
	"https://www.googleapis.com/auth/userinfo.email",
	"https://www.googleapis.com/auth/userinfo.profile",
];
const AUTH_CODE_REDIRECT_URI = "https://codeassist.google.com/authcode";
const TOKEN_URL = "https://oauth2.googleapis.com/token";

type GeminiPart = {
	text?: string;
	thought?: boolean;
	thoughtSignature?: string;
	inlineData?: { mimeType: string; data: string };
	functionCall?: { id?: string; name?: string; args?: Record<string, unknown> };
	functionResponse?: {
		id?: string;
		name: string;
		response: Record<string, unknown>;
		parts?: GeminiPart[];
	};
};

type GeminiContent = {
	role: "user" | "model";
	parts: GeminiPart[];
};

type CodeAssistResponse = {
	response?: {
		candidates?: Array<{
			content?: { parts?: GeminiPart[] };
			finishReason?: string;
		}>;
		usageMetadata?: {
			promptTokenCount?: number;
			cachedContentTokenCount?: number;
			candidatesTokenCount?: number;
			thoughtsTokenCount?: number;
			totalTokenCount?: number;
		};
	};
	traceId?: string;
};

type UserData = {
	projectId?: string;
	userTier?: string;
	userTierName?: string;
};

let cachedUserData: { accessToken: string; expiresAt: number; data: UserData } | undefined;
let toolCallCounter = 0;

function isDebugEnabled(): boolean {
	return process.env.GOOGLE_AI_PRO_DEBUG === "1" || process.env.GOOGLE_AI_PRO_DEBUG === "true";
}

function debugLog(message: string, details?: unknown): void {
	if (!isDebugEnabled()) return;
	const suffix = details === undefined ? "" : ` ${JSON.stringify(redactForLog(details)).slice(0, 5000)}`;
	console.error(`[google-ai-pro] ${message}${suffix}`);
}

function redactForLog(value: unknown): unknown {
	if (Array.isArray(value)) return value.map(redactForLog);
	if (typeof value !== "object" || value === null) return value;
	const out: Record<string, unknown> = {};
	for (const [key, item] of Object.entries(value as Record<string, unknown>)) {
		out[key] = /authorization|access|refresh|token|secret|api[-_]?key/i.test(key) ? "[redacted]" : redactForLog(item);
	}
	return out;
}

function geminiUserAgent(modelId?: string): string {
	const model = modelId ? `/${modelId}` : "";
	return `GeminiCLI-pi-extension/1.0${model} (${process.platform}; ${process.arch}; pi)`;
}

function activityRequestId(): string {
	return crypto.randomUUID().replace(/-/g, "").slice(0, 12);
}

function sleep(ms: number): Promise<void> {
	return new Promise((resolve) => setTimeout(resolve, ms));
}

function base64Url(bytes: Uint8Array): string {
	return Buffer.from(bytes).toString("base64url");
}

async function sha256Base64Url(value: string): Promise<string> {
	const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(value));
	return base64Url(new Uint8Array(digest));
}

async function generatePkce(): Promise<{ verifier: string; challenge: string; state: string }> {
	const verifierBytes = new Uint8Array(64);
	const stateBytes = new Uint8Array(32);
	crypto.getRandomValues(verifierBytes);
	crypto.getRandomValues(stateBytes);
	const verifier = base64Url(verifierBytes);
	return {
		verifier,
		challenge: await sha256Base64Url(verifier),
		state: base64Url(stateBytes),
	};
}

async function loginGoogleAiPro(callbacks: OAuthLoginCallbacks): Promise<OAuthCredentials> {
	const pkce = await generatePkce();
	const authParams = new URLSearchParams({
		client_id: OAUTH_CLIENT_ID,
		redirect_uri: AUTH_CODE_REDIRECT_URI,
		response_type: "code",
		access_type: "offline",
		scope: OAUTH_SCOPE.join(" "),
		code_challenge_method: "S256",
		code_challenge: pkce.challenge,
		state: pkce.state,
		prompt: "consent",
	});

	callbacks.onAuth({ url: `https://accounts.google.com/o/oauth2/v2/auth?${authParams}` });
	const code = (await callbacks.onPrompt({ message: "Paste the Google authorization code:" })).trim();
	if (!code) throw new Error("Google authorization code is required.");

	const tokens = await tokenRequest({
		grant_type: "authorization_code",
		code,
		code_verifier: pkce.verifier,
		redirect_uri: AUTH_CODE_REDIRECT_URI,
		client_id: OAUTH_CLIENT_ID,
		client_secret: OAUTH_CLIENT_SECRET,
	});

	if (!tokens.refresh_token) {
		throw new Error("Google did not return a refresh token. Run /logout google-ai-pro, then /login google-ai-pro again and approve offline access.");
	}

	return toOAuthCredentials(tokens);
}

async function refreshGoogleAiProToken(credentials: OAuthCredentials): Promise<OAuthCredentials> {
	const tokens = await tokenRequest({
		grant_type: "refresh_token",
		refresh_token: credentials.refresh,
		client_id: OAUTH_CLIENT_ID,
		client_secret: OAUTH_CLIENT_SECRET,
	});

	return toOAuthCredentials({ ...tokens, refresh_token: tokens.refresh_token ?? credentials.refresh });
}

async function tokenRequest(params: Record<string, string>): Promise<{
	access_token: string;
	refresh_token?: string;
	expires_in?: number;
}> {
	const response = await fetch(TOKEN_URL, {
		method: "POST",
		headers: { "Content-Type": "application/x-www-form-urlencoded" },
		body: new URLSearchParams(params),
	});

	const text = await response.text();
	let parsed: any;
	try {
		parsed = JSON.parse(text);
	} catch {
		parsed = Object.fromEntries(new URLSearchParams(text));
	}

	if (!response.ok) {
		const message = parsed?.error_description ?? parsed?.error ?? text;
		throw new Error(`Google token request failed: ${message}`);
	}
	if (!parsed?.access_token) throw new Error(`Google token response did not include access_token: ${text}`);
	return parsed;
}

function toOAuthCredentials(tokens: { access_token: string; refresh_token?: string; expires_in?: number }): OAuthCredentials {
	return {
		access: tokens.access_token,
		refresh: tokens.refresh_token ?? "",
		expires: Date.now() + (tokens.expires_in ?? 3600) * 1000 - 5 * 60 * 1000,
	};
}

function isRetryableStatus(status: number): boolean {
	return status === 429 || status === 499 || (status >= 500 && status <= 599);
}

function retryDelayMs(response: Response | undefined, attempt: number): number {
	const retryAfter = response?.headers.get("retry-after");
	if (retryAfter) {
		const seconds = Number(retryAfter);
		if (Number.isFinite(seconds)) return Math.min(seconds * 1000, 60_000);
		const date = Date.parse(retryAfter);
		if (Number.isFinite(date)) return Math.min(Math.max(date - Date.now(), 0), 60_000);
	}
	return Math.min(1000 * 2 ** (attempt - 1), 8000) + Math.floor(Math.random() * 250);
}

async function fetchWithRetry(url: string, init: RequestInit, label: string, maxAttempts = 3): Promise<Response> {
	let lastError: unknown;
	for (let attempt = 1; attempt <= maxAttempts; attempt++) {
		try {
			debugLog(`${label} attempt ${attempt}`, { url, method: init.method, headers: init.headers });
			const response = await fetch(url, init);
			if (!isRetryableStatus(response.status) || attempt === maxAttempts || init.signal?.aborted) return response;
			const delay = retryDelayMs(response, attempt);
			debugLog(`${label} retrying status ${response.status} in ${delay}ms`);
			response.body?.cancel().catch(() => {});
			await sleep(delay);
		} catch (error) {
			lastError = error;
			if (attempt === maxAttempts || init.signal?.aborted) throw error;
			const delay = retryDelayMs(undefined, attempt);
			debugLog(`${label} network retry in ${delay}ms`, error instanceof Error ? error.message : String(error));
			await sleep(delay);
		}
	}
	throw lastError instanceof Error ? lastError : new Error(String(lastError));
}

async function codeAssistFetch<T>(accessToken: string, method: string, body?: unknown, signal?: AbortSignal): Promise<T> {
	const response = await fetchWithRetry(`${CODE_ASSIST_BASE_URL}:${method}`, {
		method: "POST",
		headers: {
			Authorization: `Bearer ${accessToken}`,
			"Content-Type": "application/json",
			"User-Agent": geminiUserAgent(),
			"x-activity-request-id": activityRequestId(),
		},
		body: body === undefined ? undefined : JSON.stringify(body),
		signal,
	}, `Code Assist ${method}`);

	const text = await response.text();
	if (!response.ok) throw new Error(`Code Assist ${method} failed: ${response.status} ${text}`);
	return text ? (JSON.parse(text) as T) : (undefined as T);
}

async function getOperation<T>(accessToken: string, name: string, signal?: AbortSignal): Promise<T> {
	const response = await fetch(`${CODE_ASSIST_BASE_URL}/${name}`, {
		headers: {
			Authorization: `Bearer ${accessToken}`,
			"Content-Type": "application/json",
		},
		signal,
	});
	const text = await response.text();
	if (!response.ok) throw new Error(`Code Assist operation fetch failed: ${response.status} ${text}`);
	return JSON.parse(text) as T;
}

async function setupUser(accessToken: string, signal?: AbortSignal): Promise<UserData> {
	const now = Date.now();
	if (cachedUserData?.accessToken === accessToken && cachedUserData.expiresAt > now) return cachedUserData.data;

	const envProjectId = process.env.GOOGLE_CLOUD_PROJECT || process.env.GOOGLE_CLOUD_PROJECT_ID || undefined;
	if (envProjectId && /^\d+$/.test(envProjectId)) {
		throw new Error(`GOOGLE_CLOUD_PROJECT must be a project ID, not numeric project number: ${envProjectId}`);
	}

	const metadata = {
		ideType: "IDE_UNSPECIFIED",
		platform: "PLATFORM_UNSPECIFIED",
		pluginType: "GEMINI",
		duetProject: envProjectId,
	};

	const loadRes: any = await codeAssistFetch(accessToken, "loadCodeAssist", {
		cloudaicompanionProject: envProjectId,
		metadata,
	}, signal);

	let data: UserData | undefined;
	if (loadRes.currentTier) {
		data = {
			projectId: loadRes.cloudaicompanionProject ?? envProjectId,
			userTier: loadRes.paidTier?.id ?? loadRes.currentTier.id,
			userTierName: loadRes.paidTier?.name ?? loadRes.currentTier.name,
		};
	} else {
		const tier = (loadRes.allowedTiers ?? []).find((item: any) => item.isDefault) ?? loadRes.allowedTiers?.[0];
		if (!tier?.id) {
			const reasons = (loadRes.ineligibleTiers ?? [])
				.map((item: any) => `${item.name ?? item.id ?? "unknown"}: ${item.reason ?? item.description ?? "ineligible"}`)
				.join("; ");
			throw new Error(reasons ? `Google account is not eligible for Code Assist: ${reasons}` : "Google account is not eligible for Code Assist and no onboarding tier was returned.");
		}

		let operation: any = await codeAssistFetch(accessToken, "onboardUser", {
			tierId: tier.id,
			cloudaicompanionProject: tier.id === "FREE" ? undefined : envProjectId,
			metadata,
		}, signal);

		while (!operation.done && operation.name) {
			await new Promise((resolve) => setTimeout(resolve, 5000));
			operation = await getOperation(accessToken, operation.name, signal);
		}

		data = {
			projectId: operation.response?.cloudaicompanionProject?.id ?? envProjectId,
			userTier: tier.id,
			userTierName: tier.name,
		};
	}

	cachedUserData = { accessToken, expiresAt: now + 30_000, data };
	return data;
}

function sanitizeSurrogates(text: string): string {
	return text.replace(/[\uD800-\uDFFF]/g, "\uFFFD");
}

// Code Assist / Gemini thought signatures are opaque TYPE_BYTES values encoded
// as standard base64. They may appear on any model part, including functionCall.
// Replay only signatures from the same provider/model and only when they look
// valid; foreign or malformed signatures are rejected by Google backends.
const base64SignaturePattern = /^[A-Za-z0-9+/]+={0,2}$/;

function isValidThoughtSignature(signature?: string): boolean {
	if (!signature) return false;
	if (signature.length % 4 !== 0) return false;
	return base64SignaturePattern.test(signature);
}

function resolveThoughtSignature(sameModel: boolean, signature?: string): string | undefined {
	return sameModel && isValidThoughtSignature(signature) ? signature : undefined;
}

function requiresToolCallId(modelId: string): boolean {
	return modelId.startsWith("claude-") || modelId.startsWith("gpt-oss-");
}

function getGeminiMajorVersion(modelId: string): number | undefined {
	const match = modelId.toLowerCase().match(/^gemini(?:-live)?-(\d+)/);
	return match ? Number.parseInt(match[1]!, 10) : undefined;
}

function supportsMultimodalFunctionResponse(modelId: string): boolean {
	const geminiMajorVersion = getGeminiMajorVersion(modelId);
	return geminiMajorVersion === undefined ? true : geminiMajorVersion >= 3;
}

const NON_VISION_USER_IMAGE_PLACEHOLDER = "(image omitted: model does not support images)";
const NON_VISION_TOOL_IMAGE_PLACEHOLDER = "(tool image omitted: model does not support images)";

function replaceImagesWithPlaceholder(content: (TextContent | ImageContent)[], placeholder: string): (TextContent | ImageContent)[] {
	const result: (TextContent | ImageContent)[] = [];
	let previousWasPlaceholder = false;
	for (const block of content) {
		if (block.type === "image") {
			if (!previousWasPlaceholder) result.push({ type: "text", text: placeholder });
			previousWasPlaceholder = true;
			continue;
		}
		result.push(block);
		previousWasPlaceholder = block.type === "text" && block.text === placeholder;
	}
	return result;
}

function downgradeUnsupportedImages(messages: Message[], model: Model<Api>): Message[] {
	if (model.input.includes("image")) return messages;
	return messages.map((msg) => {
		if (msg.role === "user" && Array.isArray(msg.content)) return { ...msg, content: replaceImagesWithPlaceholder(msg.content, NON_VISION_USER_IMAGE_PLACEHOLDER) };
		if (msg.role === "toolResult") return { ...msg, content: replaceImagesWithPlaceholder(msg.content, NON_VISION_TOOL_IMAGE_PLACEHOLDER) };
		return msg;
	});
}

function transformMessages(messages: Message[], model: Model<Api>, normalizeToolCallId?: (id: string, model: Model<Api>, assistantMessage: AssistantMessage) => string): Message[] {
	const toolCallIdMap = new Map<string, string>();
	const imageAwareMessages = downgradeUnsupportedImages(messages, model);

	const transformed = imageAwareMessages.map((msg): Message => {
		if (msg.role === "user") return msg;
		if (msg.role === "toolResult") {
			const normalizedId = toolCallIdMap.get(msg.toolCallId);
			return normalizedId && normalizedId !== msg.toolCallId ? { ...msg, toolCallId: normalizedId } : msg;
		}
		if (msg.role !== "assistant") return msg;

		const isSameModel = msg.provider === model.provider && msg.api === model.api && msg.model === model.id;
		const transformedContent = msg.content.flatMap((block): AssistantMessage["content"] => {
			if (block.type === "thinking") {
				if (block.redacted) return isSameModel ? [block] : [];
				if (isSameModel && block.thinkingSignature) return [block];
				if (!block.thinking || block.thinking.trim() === "") return [];
				return isSameModel ? [block] : [{ type: "text", text: block.thinking }];
			}
			if (block.type === "text") {
				return isSameModel ? [block] : [{ type: "text", text: block.text }];
			}
			if (block.type === "toolCall") {
				let normalizedToolCall: ToolCall = block;
				if (!isSameModel && block.thoughtSignature) {
					normalizedToolCall = { ...block };
					delete normalizedToolCall.thoughtSignature;
				}
				if (!isSameModel && normalizeToolCallId) {
					const normalizedId = normalizeToolCallId(block.id, model, msg);
					if (normalizedId !== block.id) {
						toolCallIdMap.set(block.id, normalizedId);
						normalizedToolCall = { ...normalizedToolCall, id: normalizedId };
					}
				}
				return [normalizedToolCall];
			}
			return [];
		});
		return { ...msg, content: transformedContent };
	});

	const result: Message[] = [];
	let pendingToolCalls: ToolCall[] = [];
	let existingToolResultIds = new Set<string>();
	const insertSyntheticToolResults = () => {
		for (const tc of pendingToolCalls) {
			if (!existingToolResultIds.has(tc.id)) {
				result.push({
					role: "toolResult",
					toolCallId: tc.id,
					toolName: tc.name,
					content: [{ type: "text", text: "No result provided" }],
					isError: true,
					timestamp: Date.now(),
				});
			}
		}
		pendingToolCalls = [];
		existingToolResultIds = new Set<string>();
	};

	for (const msg of transformed) {
		if (msg.role === "assistant") {
			insertSyntheticToolResults();
			if (msg.stopReason === "error" || msg.stopReason === "aborted") continue;
			const toolCalls = msg.content.filter((block): block is ToolCall => block.type === "toolCall");
			if (toolCalls.length > 0) {
				pendingToolCalls = toolCalls;
				existingToolResultIds = new Set<string>();
			}
			result.push(msg);
		} else if (msg.role === "toolResult") {
			existingToolResultIds.add(msg.toolCallId);
			result.push(msg);
		} else if (msg.role === "user") {
			insertSyntheticToolResults();
			result.push(msg);
		} else {
			result.push(msg);
		}
	}
	insertSyntheticToolResults();
	return result;
}

function convertMessages(model: Model<Api>, context: Context): GeminiContent[] {
	const contents: GeminiContent[] = [];
	const normalizeToolCallId = (id: string) => requiresToolCallId(model.id) ? id.replace(/[^a-zA-Z0-9_-]/g, "_").slice(0, 64) : id;
	const transformedMessages = transformMessages(context.messages as Message[], model, normalizeToolCallId);

	for (const msg of transformedMessages) {
		if (msg.role === "user") {
			if (typeof msg.content === "string") {
				if (msg.content.trim()) contents.push({ role: "user", parts: [{ text: sanitizeSurrogates(msg.content) }] });
			} else {
				const parts = msg.content.map((item) =>
					item.type === "text"
						? { text: sanitizeSurrogates(item.text) }
						: { inlineData: { mimeType: item.mimeType, data: item.data } },
				);
				if (parts.length) contents.push({ role: "user", parts });
			}
		} else if (msg.role === "assistant") {
			const parts: GeminiPart[] = [];
			const sameModel = msg.provider === model.provider && msg.api === model.api && msg.model === model.id;
			for (const block of msg.content) {
				if (block.type === "text" && block.text.trim()) {
					const thoughtSignature = resolveThoughtSignature(sameModel, block.textSignature);
					parts.push({ text: sanitizeSurrogates(block.text), ...(thoughtSignature ? { thoughtSignature } : {}) });
				} else if (block.type === "thinking" && block.thinking.trim()) {
					const thoughtSignature = resolveThoughtSignature(sameModel, block.thinkingSignature);
					parts.push(sameModel ? { thought: true, text: sanitizeSurrogates(block.thinking), ...(thoughtSignature ? { thoughtSignature } : {}) } : { text: sanitizeSurrogates(block.thinking) });
				} else if (block.type === "toolCall") {
					const thoughtSignature = resolveThoughtSignature(sameModel, block.thoughtSignature);
					parts.push({
						functionCall: { name: block.name, args: block.arguments ?? {}, ...(requiresToolCallId(model.id) ? { id: block.id } : {}) },
						...(thoughtSignature ? { thoughtSignature } : {}),
					});
				}
			}
			if (parts.length) contents.push({ role: "model", parts });
		} else if (msg.role === "toolResult") {
			const text = msg.content.filter((c): c is TextContent => c.type === "text").map((c) => c.text).join("\n");
			const images = model.input.includes("image") ? msg.content.filter((c): c is ImageContent => c.type === "image") : [];
			const hasText = text.length > 0;
			const hasImages = images.length > 0;
			const imageParts: GeminiPart[] = images.map((image) => ({ inlineData: { mimeType: image.mimeType, data: image.data } }));
			const responseValue = hasText ? sanitizeSurrogates(text) : hasImages ? "(see attached image)" : "";
			const includeId = requiresToolCallId(model.id);
			const modelSupportsMultimodalFunctionResponse = supportsMultimodalFunctionResponse(model.id);
			const functionResponsePart: GeminiPart = {
				functionResponse: {
					name: msg.toolName,
					response: msg.isError ? { error: responseValue } : { output: responseValue },
					...(hasImages && modelSupportsMultimodalFunctionResponse ? { parts: imageParts } : {}),
					...(includeId ? { id: msg.toolCallId } : {}),
				},
			};
			const last = contents[contents.length - 1];
			if (last?.role === "user" && last.parts.some((p) => p.functionResponse)) last.parts.push(functionResponsePart);
			else contents.push({ role: "user", parts: [functionResponsePart] });
			if (hasImages && !modelSupportsMultimodalFunctionResponse) contents.push({ role: "user", parts: [{ text: "Tool result image:" }, ...imageParts] });
		}
	}
	return contents;
}

const unsupportedSchemaKeys = new Set([
	"$schema",
	"$id",
	"$anchor",
	"$dynamicAnchor",
	"$vocabulary",
	"$comment",
	"$defs",
	"definitions",
	"if",
	"then",
	"else",
	"not",
	"patternProperties",
	"propertyNames",
	"contains",
	"minContains",
	"maxContains",
	"dependentRequired",
	"dependentSchemas",
	"unevaluatedProperties",
	"unevaluatedItems",
	"prefixItems",
	"$ref",
	"readOnly",
	"writeOnly",
	"examples",
	"contentEncoding",
	"contentMediaType",
]);

function mergeObjectSchemas(schemas: unknown[]): Record<string, unknown> {
	const merged: Record<string, unknown> = { type: "object", properties: {} };
	const required = new Set<string>();
	for (const schema of schemas) {
		const clean = sanitizeSchema(schema) as Record<string, unknown>;
		if (!clean || typeof clean !== "object") continue;
		if (clean.properties && typeof clean.properties === "object") {
			merged.properties = { ...(merged.properties as Record<string, unknown>), ...(clean.properties as Record<string, unknown>) };
		}
		if (Array.isArray(clean.required)) for (const item of clean.required) if (typeof item === "string") required.add(item);
		for (const [key, value] of Object.entries(clean)) {
			if (key !== "properties" && key !== "required" && merged[key] === undefined) merged[key] = value;
		}
	}
	if (required.size) merged.required = [...required];
	return merged;
}

function sanitizeSchema(schema: unknown): unknown {
	if (Array.isArray(schema)) return schema.map(sanitizeSchema).filter((value) => value !== undefined);
	if (typeof schema !== "object" || schema === null) return schema;

	const input = schema as Record<string, unknown>;
	if (Array.isArray(input.allOf)) return mergeObjectSchemas(input.allOf);
	if (Array.isArray(input.anyOf) || Array.isArray(input.oneOf)) {
		const variants = ((input.anyOf ?? input.oneOf) as unknown[]).filter((item) => (item as Record<string, unknown>)?.type !== "null");
		return sanitizeSchema(variants[0] ?? { type: "string" });
	}

	const out: Record<string, unknown> = {};

	for (const [key, value] of Object.entries(input)) {
		if (unsupportedSchemaKeys.has(key)) continue;

		if (key === "const") {
			out.enum = [value];
			continue;
		}

		if (key === "exclusiveMinimum") {
			if (typeof value === "number") out.minimum = value;
			continue;
		}

		if (key === "exclusiveMaximum") {
			if (typeof value === "number") out.maximum = value;
			continue;
		}

		if (key === "type" && Array.isArray(value)) {
			const types = value.filter((item) => typeof item === "string") as string[];
			const nonNull = types.find((item) => item !== "null");
			if (nonNull) out.type = nonNull;
			if (types.includes("null")) out.nullable = true;
			continue;
		}

		if (key === "additionalProperties" && typeof value === "object" && value !== null) {
			out.additionalProperties = sanitizeSchema(value);
			continue;
		}

		out[key] = sanitizeSchema(value);
	}

	if (!out.type && out.properties) out.type = "object";
	if (out.type === "object" && !out.properties) out.properties = {};
	return out;
}

function convertTools(tools?: Tool[]): unknown[] | undefined {
	if (!tools?.length) return undefined;
	return [
		{
			functionDeclarations: tools.map((tool) => ({
				name: tool.name,
				description: tool.description,
				parameters: sanitizeSchema(tool.parameters),
			})),
		},
	];
}

function mapStopReason(reason?: string): StopReason {
	switch (reason) {
		case undefined:
		case "STOP":
			return "stop";
		case "MAX_TOKENS":
			return "length";
		case "MALFORMED_FUNCTION_CALL":
		case "UNEXPECTED_TOOL_CALL":
		case "SAFETY":
		case "IMAGE_SAFETY":
		case "RECITATION":
		case "IMAGE_RECITATION":
		case "BLOCKLIST":
		case "PROHIBITED_CONTENT":
		case "IMAGE_PROHIBITED_CONTENT":
		case "SPII":
		case "FINISH_REASON_UNSPECIFIED":
		case "LANGUAGE":
		case "NO_IMAGE":
		case "IMAGE_OTHER":
		case "OTHER":
			return "error";
		default:
			return "error";
	}
}

function isThinkingPart(part: GeminiPart): boolean {
	return part.thought === true;
}

function retainThoughtSignature(existing?: string, incoming?: string): string | undefined {
	return typeof incoming === "string" && incoming.length > 0 ? incoming : existing;
}

function buildGenerationConfig(model: Model<Api>, options?: SimpleStreamOptions): Record<string, unknown> | undefined {
	const config: Record<string, unknown> = {};
	if (options?.temperature !== undefined) config.temperature = options.temperature;
	if (options?.maxTokens !== undefined) config.maxOutputTokens = options.maxTokens;

	if (model.reasoning) {
		if (options?.reasoning) {
			config.thinkingConfig = isThinkingLevelModel(model.id)
				? { includeThoughts: true, thinkingLevel: thinkingLevel(options.reasoning, model.id) }
				: { includeThoughts: true, thinkingBudget: thinkingBudget(model.id, options.reasoning) };
		} else {
			config.thinkingConfig = disabledThinkingConfig(model.id);
		}
	}
	return Object.keys(config).length ? config : undefined;
}

function isGemma4Model(modelId: string): boolean {
	return /gemma-?4/i.test(modelId);
}

function isGemini3ProModel(modelId: string): boolean {
	return /gemini-3(?:\.\d+)?-pro/i.test(modelId);
}

function isGemini3FlashModel(modelId: string): boolean {
	return /gemini-3(?:\.\d+)?-flash/i.test(modelId);
}

function isThinkingLevelModel(modelId: string): boolean {
	return isGemini3ProModel(modelId) || isGemini3FlashModel(modelId) || isGemma4Model(modelId);
}

function disabledThinkingConfig(modelId: string): Record<string, unknown> {
	if (isGemini3ProModel(modelId)) return { thinkingLevel: "LOW" };
	if (isGemini3FlashModel(modelId) || isGemma4Model(modelId)) return { thinkingLevel: "MINIMAL" };
	return { thinkingBudget: 0 };
}

function thinkingLevel(level: string, modelId: string): string {
	if (isGemini3ProModel(modelId)) return level === "minimal" || level === "low" ? "LOW" : "HIGH";
	if (isGemma4Model(modelId)) return level === "minimal" || level === "low" ? "MINIMAL" : "HIGH";
	switch (level) {
		case "minimal":
			return "MINIMAL";
		case "low":
			return "LOW";
		case "medium":
			return "MEDIUM";
		case "high":
		case "xhigh":
		default:
			return "HIGH";
	}
}

function thinkingBudget(modelId: string, level: string): number {
	const budgets = modelId.includes("2.5-pro")
		? { minimal: 128, low: 2048, medium: 8192, high: 32768, xhigh: 32768 }
		: modelId.includes("2.5-flash-lite")
			? { minimal: 512, low: 2048, medium: 8192, high: 24576, xhigh: 24576 }
			: { minimal: 128, low: 2048, medium: 8192, high: 24576, xhigh: 24576 };
	return budgets[level as keyof typeof budgets] ?? -1;
}

function streamGoogleAiPro(model: Model<Api>, context: Context, options?: SimpleStreamOptions): AssistantMessageEventStream {
	const stream = createAssistantMessageEventStream();

	(async () => {
		const output: AssistantMessage = {
			role: "assistant",
			content: [],
			api: model.api,
			provider: model.provider,
			model: model.id,
			usage: {
				input: 0,
				output: 0,
				cacheRead: 0,
				cacheWrite: 0,
				totalTokens: 0,
				cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, total: 0 },
			},
			stopReason: "stop",
			timestamp: Date.now(),
		};

		try {
			const accessToken = options?.apiKey;
			if (!accessToken) throw new Error("No Google OAuth token. Run /login google-ai-pro first.");

			const userData = await setupUser(accessToken, options.signal);
			const contents = convertMessages(model, context);
			if (contents.length === 0) throw new Error("Cannot send an empty conversation to Code Assist.");
			const generationConfig = buildGenerationConfig(model, options);
			const payload = {
				model: model.id,
				project: userData.projectId,
				user_prompt_id: crypto.randomUUID(),
				request: {
					contents,
					...(context.systemPrompt ? { systemInstruction: { role: "user", parts: [{ text: sanitizeSurrogates(context.systemPrompt) }] } } : {}),
					...(context.tools?.length ? { tools: convertTools(context.tools), toolConfig: { functionCallingConfig: { mode: "AUTO" } } } : {}),
					...(generationConfig ? { generationConfig } : {}),
				},
			};
			debugLog("request payload", payload);

			const nextPayload = await options?.onPayload?.(payload, model);
			const finalPayload = nextPayload === undefined ? payload : nextPayload;

			const response = await fetchWithRetry(`${CODE_ASSIST_BASE_URL}:streamGenerateContent?alt=sse`, {
				method: "POST",
				headers: {
					Authorization: `Bearer ${accessToken}`,
					Accept: "text/event-stream",
					"Content-Type": "application/json",
					"User-Agent": geminiUserAgent(model.id),
					"x-activity-request-id": activityRequestId(),
					...(options?.headers ?? {}),
				},
				body: JSON.stringify(finalPayload),
				signal: options?.signal,
			}, "Code Assist streamGenerateContent");

			debugLog("stream response", { status: response.status, headers: Object.fromEntries(response.headers.entries()) });
			await options?.onResponse?.({ status: response.status, headers: Object.fromEntries(response.headers.entries()) }, model);
			if (!response.ok) throw new Error(`Code Assist streamGenerateContent failed: ${response.status} ${await response.text()}`);
			if (!response.body) throw new Error("Code Assist response did not include a stream body.");

			stream.push({ type: "start", partial: output });
			const chunkCount = await consumeSse(response.body, (chunk) => handleCodeAssistChunk(chunk, model, output, stream));
			finalizeOpenContentBlock(output, stream);

			if (options?.signal?.aborted) throw new Error("Request was aborted");
			if (output.stopReason === "aborted" || output.stopReason === "error") throw new Error("An unknown error occurred");
			if (chunkCount === 0 || output.content.length === 0) {
				throw new Error(`Code Assist returned an empty stream (${chunkCount} chunks). Try /reload, then retry; if it persists, set GOOGLE_AI_PRO_DEBUG=1 and rerun to inspect provider payload/stream metadata.`);
			}
			stream.push({ type: "done", reason: output.stopReason, message: output });
			stream.end();
		} catch (error) {
			output.stopReason = options?.signal?.aborted ? "aborted" : "error";
			output.errorMessage = error instanceof Error ? error.message : String(error);
			stream.push({ type: "error", reason: output.stopReason, error: output });
			stream.end();
		}
	})();

	return stream;
}

async function consumeSse(body: ReadableStream<Uint8Array>, onJson: (data: CodeAssistResponse) => void): Promise<number> {
	const reader = body.getReader();
	const decoder = new TextDecoder();
	let buffer = "";
	let count = 0;

	const consumeEvent = (event: string) => {
		const data = event
			.split("\n")
			.map((line) => line.trimEnd())
			.filter((line) => line.startsWith("data:"))
			.map((line) => line.slice(5).trim())
			.join("\n");
		if (!data || data === "[DONE]") return;
		try {
			const parsed = JSON.parse(data) as CodeAssistResponse;
			debugLog("sse chunk", parsed);
			onJson(parsed);
			count++;
		} catch (error) {
			debugLog("malformed sse chunk", data);
			throw new Error(`Code Assist returned malformed SSE JSON: ${error instanceof Error ? error.message : String(error)}`);
		}
	};

	while (true) {
		const { value, done } = await reader.read();
		if (done) break;
		buffer += decoder.decode(value, { stream: true }).replace(/\r\n/g, "\n").replace(/\r/g, "\n");
		let boundary: number;
		while ((boundary = buffer.indexOf("\n\n")) >= 0) {
			const event = buffer.slice(0, boundary);
			buffer = buffer.slice(boundary + 2);
			consumeEvent(event);
		}
	}

	buffer += decoder.decode();
	buffer = buffer.replace(/\r\n/g, "\n").replace(/\r/g, "\n").trim();
	if (buffer) consumeEvent(buffer);
	return count;
}

function finalizeOpenContentBlock(output: AssistantMessage, stream: AssistantMessageEventStream): void {
	const index = output.content.length - 1;
	const block = output.content[index];
	if (block?.type === "text") stream.push({ type: "text_end", contentIndex: index, content: block.text, partial: output });
	if (block?.type === "thinking") stream.push({ type: "thinking_end", contentIndex: index, content: block.thinking, partial: output });
}

function handleCodeAssistChunk(chunk: CodeAssistResponse, model: Model<Api>, output: AssistantMessage, stream: AssistantMessageEventStream): void {
	output.responseId ||= chunk.traceId;
	const candidate = chunk.response?.candidates?.[0];
	for (const part of candidate?.content?.parts ?? []) {
		if (part.text !== undefined) {
			const thinking = isThinkingPart(part);
			let block = output.content.at(-1) as TextContent | ThinkingContent | ToolCall | undefined;
			if (!block || (thinking && block.type !== "thinking") || (!thinking && block.type !== "text")) {
				if (block?.type === "text") stream.push({ type: "text_end", contentIndex: output.content.length - 1, content: block.text, partial: output });
				if (block?.type === "thinking") stream.push({ type: "thinking_end", contentIndex: output.content.length - 1, content: block.thinking, partial: output });
				block = thinking ? { type: "thinking", thinking: "", thinkingSignature: undefined } : { type: "text", text: "", textSignature: undefined };
				output.content.push(block);
				stream.push({ type: thinking ? "thinking_start" : "text_start", contentIndex: output.content.length - 1, partial: output } as any);
			}
			if (block.type === "thinking") {
				block.thinking += part.text;
				block.thinkingSignature = retainThoughtSignature(block.thinkingSignature, part.thoughtSignature);
				stream.push({ type: "thinking_delta", contentIndex: output.content.length - 1, delta: part.text, partial: output });
			} else if (block.type === "text") {
				block.text += part.text;
				block.textSignature = retainThoughtSignature(block.textSignature, part.thoughtSignature);
				stream.push({ type: "text_delta", contentIndex: output.content.length - 1, delta: part.text, partial: output });
			}
		}

		if (part.functionCall) {
			const last = output.content.at(-1);
			if (last?.type === "text") stream.push({ type: "text_end", contentIndex: output.content.length - 1, content: last.text, partial: output });
			if (last?.type === "thinking") stream.push({ type: "thinking_end", contentIndex: output.content.length - 1, content: last.thinking, partial: output });
			const providedId = part.functionCall.id;
			const needsNewId = !providedId || output.content.some((block) => block.type === "toolCall" && block.id === providedId);
			const toolCallId = needsNewId ? `${part.functionCall.name ?? "tool"}_${Date.now()}_${++toolCallCounter}` : providedId;
			const toolCall: ToolCall = {
				type: "toolCall",
				id: toolCallId,
				name: part.functionCall.name ?? "",
				arguments: part.functionCall.args ?? {},
				...(part.thoughtSignature ? { thoughtSignature: part.thoughtSignature } : {}),
			};
			output.content.push(toolCall);
			const index = output.content.length - 1;
			stream.push({ type: "toolcall_start", contentIndex: index, partial: output });
			stream.push({ type: "toolcall_delta", contentIndex: index, delta: JSON.stringify(toolCall.arguments), partial: output });
			stream.push({ type: "toolcall_end", contentIndex: index, toolCall, partial: output });
		}
	}

	if (candidate?.finishReason) {
		output.stopReason = mapStopReason(candidate.finishReason);
		if (output.content.some((block) => block.type === "toolCall")) output.stopReason = "toolUse";
	}

	const usage = chunk.response?.usageMetadata;
	if (usage) {
		output.usage = {
			input: (usage.promptTokenCount ?? 0) - (usage.cachedContentTokenCount ?? 0),
			output: (usage.candidatesTokenCount ?? 0) + (usage.thoughtsTokenCount ?? 0),
			cacheRead: usage.cachedContentTokenCount ?? 0,
			cacheWrite: 0,
			totalTokens: usage.totalTokenCount ?? 0,
			cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, total: 0 },
		};
		calculateCost(model, output.usage);
	}
}

const zeroCost = { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 };

export default function (pi: ExtensionAPI) {
	pi.registerProvider(PROVIDER, {
		name: "Google AI Pro (Gemini CLI)",
		baseUrl: CODE_ASSIST_BASE_URL,
		apiKey: "$GOOGLE_AI_PRO_ACCESS_TOKEN",
		api: API,
		models: [
			{ id: "gemini-3-pro-preview", name: "Gemini 3 Pro Preview (AI Pro)", reasoning: true, input: ["text", "image"], cost: zeroCost, contextWindow: 1_000_000, maxTokens: 65_536 },
			{ id: "gemini-3.1-pro-preview", name: "Gemini 3.1 Pro Preview (AI Pro)", reasoning: true, input: ["text", "image"], cost: zeroCost, contextWindow: 1_000_000, maxTokens: 65_536 },
			{ id: "gemini-3.5-flash", name: "Gemini 3.5 Flash (AI Pro)", reasoning: true, input: ["text", "image"], cost: zeroCost, contextWindow: 1_000_000, maxTokens: 65_536 },
			{ id: "gemini-2.5-pro", name: "Gemini 2.5 Pro (AI Pro)", reasoning: true, input: ["text", "image"], cost: zeroCost, contextWindow: 1_000_000, maxTokens: 65_536 },
			{ id: "gemini-2.5-flash", name: "Gemini 2.5 Flash (AI Pro)", reasoning: true, input: ["text", "image"], cost: zeroCost, contextWindow: 1_000_000, maxTokens: 65_536 },
			{ id: "gemini-3.1-flash-lite", name: "Gemini 3.1 Flash Lite (AI Pro)", reasoning: true, input: ["text", "image"], cost: zeroCost, contextWindow: 1_000_000, maxTokens: 65_536 },
		],
		oauth: {
			name: "Google AI Pro / Code Assist",
			login: loginGoogleAiPro,
			refreshToken: refreshGoogleAiProToken,
			getApiKey: (credentials) => credentials.access,
		},
		streamSimple: streamGoogleAiPro,
	});
}
