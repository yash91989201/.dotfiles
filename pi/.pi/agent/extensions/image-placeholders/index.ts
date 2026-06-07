import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { CustomEditor } from "@earendil-works/pi-coding-agent";
import { existsSync, readFileSync, statSync } from "fs";
import { homedir } from "os";
import { join } from "path";

const LEGACY_PLACEHOLDER_PATTERN = /\[Img\s+\d+(?:\s+-\s+\d+[KMG]?B)?\]/g;
const STATE_KEY = Symbol.for("pi.image-placeholders.state.v4");
const PATCHED_KEY = Symbol.for("pi.image-placeholders.editor-prototype-patched.v4");
const MARKER_BASE = 0xe000;
const MARKER_COUNT = 0xf8ff - MARKER_BASE;

type ColorValue = string | number;

type ImageEntry = {
	label: string;
	path: string;
};

type ImagePlaceholderState = {
	entries: Map<string, ImageEntry>;
	legacyPaths: Map<string, string>;
	counter: number;
	themeRef: any;
	bgVisualAnsi: string | null;
};

const state = ((globalThis as any)[STATE_KEY] ??= {
	entries: new Map<string, ImageEntry>(),
	legacyPaths: new Map<string, string>(),
	counter: 0,
	themeRef: null,
	bgVisualAnsi: null,
}) as ImagePlaceholderState;

function isImagePath(text: string): boolean {
	return /\.(png|jpe?g|gif|webp|bmp|avif|tiff?)$/i.test(text)
		&& (text.includes("pi-clipboard") || text.includes("/tmp/") || text.includes("\\tmp\\"));
}

function formatSize(bytes: number): string {
	if (bytes < 1024) return `${bytes}B`;
	if (bytes < 1024 * 1024) return `${Math.round(bytes / 1024)}K`;
	return `${Math.round(bytes / (1024 * 1024))}M`;
}

function getImageSize(filePath: string): string {
	try {
		return formatSize(statSync(filePath).size);
	} catch {
		return "";
	}
}

function makeLabel(filePath: string): string {
	state.counter++;
	const sizeInfo = getImageSize(filePath);
	return sizeInfo ? `[Img ${state.counter} - ${sizeInfo}]` : `[Img ${state.counter}]`;
}

function markerForCounter(counter: number): string | null {
	const offset = (counter - 1) % MARKER_COUNT;
	const marker = String.fromCharCode(MARKER_BASE + offset);
	return state.entries.has(marker) ? null : marker;
}

function registerImagePath(filePath: string): string {
	const label = makeLabel(filePath);
	const marker = markerForCounter(state.counter);

	// Store a private-use single-character marker in editor state. The editor's
	// native backspace deletes it in one step, while render() displays the full
	// [Img N - SIZE] label. This is more reliable than trying to make many
	// ordinary characters behave atomically.
	if (marker) {
		state.entries.set(marker, { label, path: filePath });
		return marker;
	}

	// Extremely unlikely fallback after thousands of images in one process.
	state.legacyPaths.set(label, filePath);
	return label;
}

function hexToRgb(hex: string): { r: number; g: number; b: number } | null {
	const match = hex.match(/^#([0-9a-f]{6})$/i);
	if (!match) return null;
	return {
		r: Number.parseInt(match[1].slice(0, 2), 16),
		g: Number.parseInt(match[1].slice(2, 4), 16),
		b: Number.parseInt(match[1].slice(4, 6), 16),
	};
}

const CUBE_VALUES = [0, 95, 135, 175, 215, 255];
const GRAY_VALUES = Array.from({ length: 24 }, (_, i) => 8 + i * 10);

function closestIndex(values: number[], target: number): number {
	let best = 0;
	let bestDistance = Infinity;
	for (let i = 0; i < values.length; i++) {
		const distance = Math.abs(values[i] - target);
		if (distance < bestDistance) {
			best = i;
			bestDistance = distance;
		}
	}
	return best;
}

function colorDistance(r1: number, g1: number, b1: number, r2: number, g2: number, b2: number): number {
	const dr = r1 - r2;
	const dg = g1 - g2;
	const db = b1 - b2;
	return dr * dr * 0.299 + dg * dg * 0.587 + db * db * 0.114;
}

function rgbTo256(r: number, g: number, b: number): number {
	const rIdx = closestIndex(CUBE_VALUES, r);
	const gIdx = closestIndex(CUBE_VALUES, g);
	const bIdx = closestIndex(CUBE_VALUES, b);
	const cubeDistance = colorDistance(r, g, b, CUBE_VALUES[rIdx], CUBE_VALUES[gIdx], CUBE_VALUES[bIdx]);
	const cubeIndex = 16 + 36 * rIdx + 6 * gIdx + bIdx;

	const gray = Math.round(0.299 * r + 0.587 * g + 0.114 * b);
	const grayIdx = closestIndex(GRAY_VALUES, gray);
	const grayDistance = colorDistance(r, g, b, GRAY_VALUES[grayIdx], GRAY_VALUES[grayIdx], GRAY_VALUES[grayIdx]);
	const grayIndex = 232 + grayIdx;

	return Math.max(r, g, b) - Math.min(r, g, b) < 10 && grayDistance < cubeDistance ? grayIndex : cubeIndex;
}

function resolveColorValue(value: ColorValue | undefined, vars: Record<string, ColorValue>, seen = new Set<string>()): ColorValue | null {
	if (value === undefined) return null;
	if (typeof value === "number" || value === "" || value.startsWith("#")) return value;
	if (seen.has(value)) return null;
	seen.add(value);
	return resolveColorValue(vars[value], vars, seen);
}

function bgAnsi(value: ColorValue, colorMode: "truecolor" | "256color"): string | null {
	if (value === "") return "\x1b[49m";
	if (typeof value === "number") return `\x1b[48;5;${value}m`;

	const rgb = hexToRgb(value);
	if (!rgb) return null;
	if (colorMode === "256color") return `\x1b[48;5;${rgbTo256(rgb.r, rgb.g, rgb.b)}m`;
	return `\x1b[48;2;${rgb.r};${rgb.g};${rgb.b}m`;
}

function themePathCandidates(theme: any, cwd: string): string[] {
	const name = typeof theme?.name === "string" ? theme.name : "";
	return [
		theme?.sourcePath,
		name ? join(homedir(), ".pi", "agent", "themes", `${name}.json`) : undefined,
		name ? join(cwd, ".pi", "themes", `${name}.json`) : undefined,
	].filter((candidate): candidate is string => typeof candidate === "string" && candidate.length > 0);
}

function loadBgVisualAnsi(theme: any, cwd: string): string | null {
	for (const themePath of themePathCandidates(theme, cwd)) {
		if (!existsSync(themePath)) continue;
		try {
			const themeJson = JSON.parse(readFileSync(themePath, "utf8"));
			const vars = (themeJson.vars ?? {}) as Record<string, ColorValue>;
			const bgVisual = resolveColorValue(vars.bgVisual ?? themeJson.colors?.bgVisual, vars);
			if (bgVisual === null) continue;

			const colorMode = theme?.getColorMode?.() === "256color" ? "256color" : "truecolor";
			const ansi = bgAnsi(bgVisual, colorMode);
			if (ansi) return ansi;
		} catch {
			// Try next candidate, then fall back to selectedBg.
		}
	}
	return null;
}

function refreshTheme(theme: any, cwd: string): void {
	state.themeRef = theme;
	state.bgVisualAnsi = loadBgVisualAnsi(theme, cwd);
}

function placeholderBgAnsi(): string | null {
	if (state.bgVisualAnsi) return state.bgVisualAnsi;
	try {
		return state.themeRef?.getBgAnsi?.("selectedBg") ?? null;
	} catch {
		return null;
	}
}

function styleLabel(label: string): string {
	const bg = placeholderBgAnsi();
	return bg ? `${bg}${label}\x1b[49m` : label;
}

function expandMarkersForDisplay(line: string): string {
	let result = "";
	for (const char of line) {
		const entry = state.entries.get(char);
		result += entry ? styleLabel(entry.label) : char;
	}
	// Do not run LEGACY_PLACEHOLDER_PATTERN over result: marker expansion creates
	// the visible [Img ...] label, and styling it again would double-wrap ANSI and
	// break cursor placement. Legacy plain-text placeholders are still expanded on
	// submit and can be removed atomically by the fallback backspace hook.
	return result;
}

function displayCursorCol(line: string, cursorCol: number): number {
	let displayCol = 0;
	for (let i = 0; i < Math.min(cursorCol, line.length); i++) {
		const entry = state.entries.get(line[i]);
		displayCol += entry ? styleLabel(entry.label).length : 1;
	}
	return displayCol;
}

function renderWithDisplayMarkers(editor: any, originalRender: Function, width: number): string[] {
	const originalLines = editor.state.lines;
	const originalCursorCol = editor.state.cursorCol;
	const currentLine = editor.state.cursorLine;

	try {
		editor.state.lines = originalLines.map(expandMarkersForDisplay);
		editor.state.cursorCol = displayCursorCol(originalLines[currentLine] ?? "", originalCursorCol);
		return originalRender.call(editor, width);
	} finally {
		editor.state.lines = originalLines;
		editor.state.cursorCol = originalCursorCol;
	}
}

function readEscapeSequence(raw: string, index: number): string | null {
	if (raw[index] !== "\x1b") return null;

	const next = raw[index + 1];
	if (next === "[") {
		let end = index + 2;
		while (end < raw.length && !/[A-Za-z~]/.test(raw[end])) end++;
		return end < raw.length ? raw.slice(index, end + 1) : raw.slice(index);
	}

	if (next === "]" || next === "_") {
		const bel = raw.indexOf("\x07", index + 2);
		const st = raw.indexOf("\x1b\\", index + 2);
		if (bel === -1 && st === -1) return raw.slice(index);
		if (bel !== -1 && (st === -1 || bel < st)) return raw.slice(index, bel + 1);
		return raw.slice(index, st + 2);
	}

	return raw.slice(index, Math.min(index + 2, raw.length));
}

function stripTerminalControls(raw: string): string {
	let clean = "";
	let i = 0;
	while (i < raw.length) {
		const escape = readEscapeSequence(raw, i);
		if (escape) {
			i += escape.length;
			continue;
		}
		clean += raw[i];
		i++;
	}
	return clean;
}

function legacyPlaceholderAtCursor(line: string, cursorCol: number): { start: number; end: number } | null {
	LEGACY_PLACEHOLDER_PATTERN.lastIndex = 0;
	for (const match of line.matchAll(LEGACY_PLACEHOLDER_PATTERN)) {
		if (match.index === undefined) continue;
		const start = match.index;
		const end = start + match[0].length;
		if (cursorCol > start && cursorCol <= end) return { start, end };
	}
	return null;
}

function deleteTextRange(editor: any, lineIndex: number, start: number, end: number): boolean {
	const line = editor.state?.lines?.[lineIndex] ?? "";
	editor.historyIndex = -1;
	editor.lastAction = null;
	editor.pushUndoSnapshot?.();
	editor.state.lines[lineIndex] = line.slice(0, start) + line.slice(end);
	editor.setCursorCol?.(start);
	if (editor.onChange) editor.onChange(editor.getText());
	if (editor.autocompleteState) editor.updateAutocomplete?.();
	return true;
}

function deleteMarkerPlaceholderAtCursor(editor: any): boolean {
	const lineIndex = editor.state?.cursorLine ?? editor.getCursor?.().line ?? 0;
	const cursorCol = editor.state?.cursorCol ?? editor.getCursor?.().col ?? 0;
	const line = editor.state?.lines?.[lineIndex] ?? editor.getLines?.()[lineIndex] ?? "";

	// If cursor is after the auto-inserted space, remove marker + space together.
	if (cursorCol >= 2 && line[cursorCol - 1] === " " && state.entries.has(line[cursorCol - 2])) {
		return deleteTextRange(editor, lineIndex, cursorCol - 2, cursorCol);
	}

	// If cursor is directly after the marker, remove marker.
	if (cursorCol >= 1 && state.entries.has(line[cursorCol - 1])) {
		return deleteTextRange(editor, lineIndex, cursorCol - 1, cursorCol);
	}

	return false;
}

function deleteLegacyPlaceholderAtCursor(editor: any): boolean {
	const lineIndex = editor.state?.cursorLine ?? editor.getCursor?.().line ?? 0;
	const cursorCol = editor.state?.cursorCol ?? editor.getCursor?.().col ?? 0;
	const line = editor.state?.lines?.[lineIndex] ?? editor.getLines?.()[lineIndex] ?? "";
	const match = legacyPlaceholderAtCursor(line, cursorCol);
	if (!match) return false;

	return deleteTextRange(editor, lineIndex, match.start, match.end);
}

function installPrototypeFallback(): void {
	const editorProto = Object.getPrototypeOf(CustomEditor.prototype) as any;
	if (!editorProto || editorProto[PATCHED_KEY]) return;
	editorProto[PATCHED_KEY] = true;

	const originalInsertTextAtCursor = editorProto.insertTextAtCursor;
	if (typeof originalInsertTextAtCursor === "function") {
		editorProto.insertTextAtCursor = function (text: string) {
			const trimmed = typeof text === "string" ? text.trim() : "";
			if (trimmed && isImagePath(trimmed)) {
				return originalInsertTextAtCursor.call(this, `${registerImagePath(trimmed)} `);
			}
			return originalInsertTextAtCursor.call(this, text);
		};
	}

	const originalHandlePaste = editorProto.handlePaste;
	if (typeof originalHandlePaste === "function") {
		editorProto.handlePaste = function (text: string) {
			const trimmed = typeof text === "string" ? text.trim() : "";
			if (trimmed && isImagePath(trimmed)) {
				return this.insertTextAtCursor(`${registerImagePath(trimmed)} `);
			}
			return originalHandlePaste.call(this, text);
		};
	}

	const originalHandleBackspace = editorProto.handleBackspace;
	if (typeof originalHandleBackspace === "function") {
		editorProto.handleBackspace = function () {
			if (deleteMarkerPlaceholderAtCursor(this) || deleteLegacyPlaceholderAtCursor(this)) return;
			return originalHandleBackspace.call(this);
		};
	}

	const originalRender = editorProto.render;
	if (typeof originalRender === "function") {
		editorProto.render = function (width: number) {
			return renderWithDisplayMarkers(this, originalRender, width);
		};
	}
}

class ImagePlaceholderEditor extends CustomEditor {
	private pendingBracketedPaste: string | null = null;

	override insertTextAtCursor(text: string): void {
		const trimmed = text.trim();
		if (trimmed && isImagePath(trimmed)) {
			super.insertTextAtCursor(`${registerImagePath(trimmed)} `);
			return;
		}
		super.insertTextAtCursor(text);
	}

	override handleInput(data: string): void {
		if (this.handleBracketedPaste(data)) return;
		super.handleInput(data);
	}

	override render(width: number): string[] {
		// Editor.prototype.render is patched by installPrototypeFallback(), so super.render()
		// already expands private marker chars to styled [Img N - SIZE] labels.
		return super.render(width);
	}

	private handleBracketedPaste(data: string): boolean {
		if (this.pendingBracketedPaste === null && !data.includes("\x1b[200~")) return false;

		if (this.pendingBracketedPaste === null) {
			const startIndex = data.indexOf("\x1b[200~");
			const before = data.slice(0, startIndex);
			if (before) super.handleInput(before);
			this.pendingBracketedPaste = data.slice(startIndex + 6);
		} else {
			this.pendingBracketedPaste += data;
		}

		const endIndex = this.pendingBracketedPaste.indexOf("\x1b[201~");
		if (endIndex === -1) return true;

		const pasted = this.pendingBracketedPaste.slice(0, endIndex);
		const remaining = this.pendingBracketedPaste.slice(endIndex + 6);
		this.pendingBracketedPaste = null;

		const trimmed = pasted.trim();
		if (trimmed && isImagePath(trimmed)) {
			this.insertTextAtCursor(trimmed);
			if (remaining) this.handleInput(remaining);
			return true;
		}

		super.handleInput(`\x1b[200~${pasted}\x1b[201~`);
		if (remaining) this.handleInput(remaining);
		return true;
	}
}

export default function (pi: ExtensionAPI) {
	pi.on("session_start", (_event, ctx) => {
		refreshTheme(ctx.ui.theme, ctx.cwd);
		installPrototypeFallback();
		ctx.ui.setEditorComponent((tui, theme, keybindings) => new ImagePlaceholderEditor(tui, theme, keybindings));
	});

	pi.on("session_shutdown", (_event, ctx) => {
		ctx.ui.setEditorComponent(undefined);
	});

	pi.on("input", (event) => {
		let text = stripTerminalControls(event.text);
		let changed = false;

		for (const [marker, entry] of state.entries) {
			if (text.includes(marker)) {
				text = text.replaceAll(marker, entry.path);
				changed = true;
			}
		}

		for (const [placeholder, path] of state.legacyPaths) {
			if (text.includes(placeholder)) {
				text = text.replaceAll(placeholder, path);
				changed = true;
			}
		}

		if (changed) return { action: "transform" as const, text };
	});
}
