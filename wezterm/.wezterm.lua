-- ══════════════════════════════════════════════════════════════
--  WezTerm Configuration
--  TokyoNight theme · tmux-like leader workflow
-- ══════════════════════════════════════════════════════════════
--
-- ┌────────────────────────────────────────────────────────────┐
-- │                    KEYMAP QUICK REFERENCE                   │
-- ├────────────────────────────────────────────────────────────┤
-- │  Leader = `  (backtick, 1s timeout)                        │
-- ├──────────────┬─────────────────────────────────────────────┤
-- │  LEADER      │  Action                                     │
-- ├──────────────┼─────────────────────────────────────────────┤
-- │  ``          │  Send literal backtick                      │
-- │  r           │  Reload config                              │
-- ├──────────────┼─────────────────────────────────────────────┤
-- │  c / n       │  New tab                                    │
-- │  q           │  Close pane                                 │
-- │  Q           │  Close tab                                  │
-- │  , / e       │  Rename tab                                 │
-- ├──────────────┼─────────────────────────────────────────────┤
-- │  " / - / V   │  Split vertical                             │
-- │  % / H / |   │  Split horizontal                           │
-- ├──────────────┼─────────────────────────────────────────────┤
-- │  h/j/k/l     │  Move pane (vim-aware, passes through nvim)│
-- │  ←↑↓→        │  Resize pane                                │
-- │  z           │  Zoom pane                                  │
-- │  p           │  Pick pane                                  │
-- │  s           │  Swap pane                                  │
-- │  o           │  Next pane                                   │
-- ├──────────────┼─────────────────────────────────────────────┤
-- │  1–9         │  Switch to tab N                            │
-- │  Ctrl+h/l    │  Prev / next tab                            │
-- │  { / }       │  Move tab left / right                      │
-- │  Tab         │  Last tab                                   │
-- ├──────────────┼─────────────────────────────────────────────┤
-- │  S           │  Toggle tab bar                             │
-- │  w           │  Workspace launcher                         │
-- │  W           │  New workspace                              │
-- │  ( / )       │  Prev / next workspace                      │
-- │  $           │  Rename workspace                           │
-- ├──────────────┼─────────────────────────────────────────────┤
-- │  [ / y       │  Enter copy mode                            │
-- │  v           │  Paste from primary selection               │
-- │  .           │  Debug overlay                              │
-- ├──────────────┼─────────────────────────────────────────────┤
-- │  Ctrl+C/V    │  Copy / Paste (clipboard)                   │
-- │  Ctrl+F      │  Search                                     │
-- │  Ctrl+P      │  Command palette                            │
-- │  Ctrl+U/D    │  Scroll half page up / down                 │
-- │  Ctrl+=/-/0  │  Increase / reset / decrease font size      │
-- │  Ctrl+L      │  Clear scrollback                           │
-- │  Shift+PgUp  │  Scroll page up / down                      │
-- │  Shift+Home  │  Scroll to top / bottom                     │
-- │  F11         │  Toggle fullscreen                          │
-- ├──────────────┼─────────────────────────────────────────────┤
-- │  COPY MODE   │  (vim-like)                                 │
-- │  h/j/k/l     │  Move                                       │
-- │  w/b/e       │  Word motions                               │
-- │  0/$         │  Line start / end                           │
-- │  g/G         │  Top / bottom of scrollback                 │
-- │  v/V/Ctrl+V  │  Cell / line / block selection              │
-- │  y/Enter     │  Yank & close                               │
-- │  //n/N       │  Search next / prev                         │
-- │  q/Esc       │  Exit copy mode                             │
-- └──────────────┴─────────────────────────────────────────────┘

local wezterm = require("wezterm")
local act = wezterm.action
local mux = wezterm.mux

local config = wezterm.config_builder()

-- ══════════════════════════════════════════════════════════════
--  Color Palette — TokyoNight
-- ══════════════════════════════════════════════════════════════

local c = {
	bg = "#1a1b26",
	bg_dark = "#15161e",
	bg_popup = "#1f2335",
	bg_hl = "#292e42",

	fg = "#c0caf5",
	fg_dark = "#a9b1d6",
	fg_gutter = "#3b4261",

	black = "#414868",
	comment = "#565f89",
	dark3 = "#545c7e",

	blue = "#7aa2f7",
	cyan = "#7dcfff",
	green = "#9ece6a",
	orange = "#ff9e64",
	yellow = "#e0af68",
	magenta = "#bb9af7",
	red = "#f7768e",
	red_dark = "#db4b4b",

	bg_visual = "#33467c",

	blue_b = "#8db0ff",
	cyan_b = "#a4daff",
	green_b = "#9fe044",
	yellow_b = "#faba4a",
	magenta_b = "#c7a9ff",
	red_b = "#ff899d",
}

-- ══════════════════════════════════════════════════════════════
--  General / Performance
-- ══════════════════════════════════════════════════════════════

-- Native Ubuntu package: prefer the Wayland/WebGPU path.
-- If Wayland is unavailable, WezTerm falls back automatically.
config.enable_wayland = true
config.front_end = "WebGpu"
config.webgpu_power_preference = "HighPerformance"

config.check_for_updates = false
config.warn_about_missing_glyphs = false
config.audible_bell = "Disabled"

config.max_fps = 120
config.animation_fps = 120
config.cursor_blink_rate = 0
config.default_cursor_style = "SteadyBlock"

-- The status callback checks git/battery state; update less often so it
-- does not compete with Neovim during heavy redraws.
config.status_update_interval = 5000

config.window_close_confirmation = "NeverPrompt"

config.enable_kitty_keyboard = true

-- ══════════════════════════════════════════════════════════════
--  Window
-- ══════════════════════════════════════════════════════════════

config.window_decorations = "NONE"
config.initial_cols = 120
config.initial_rows = 30
config.enable_scroll_bar = false
config.scrollback_lines = 10000

config.window_padding = { left = 0, right = 0, top = 0, bottom = 0 }

config.inactive_pane_hsb = {
	saturation = 0.95,
	brightness = 0.8,
}

wezterm.on("gui-startup", function()
	local _, _, window = mux.spawn_window({})
	window:gui_window():maximize()
end)

-- ══════════════════════════════════════════════════════════════
--  Font
-- ══════════════════════════════════════════════════════════════

config.font = wezterm.font_with_fallback({
	{ family = "JetBrainsMono Nerd Font Mono", weight = "Medium" },
	{ family = "JetBrains Mono", weight = "Medium" },
	{ family = "Symbols Nerd Font Mono" },
	{ family = "Noto Color Emoji" },
})

config.font_size = 11
config.line_height = 1.1
config.freetype_load_target = "Normal"
config.freetype_render_target = "Normal"
config.underline_position = -3
config.underline_thickness = 1

-- ══════════════════════════════════════════════════════════════
--  Colors — Theme
-- ══════════════════════════════════════════════════════════════

config.colors = {
	background = c.bg,
	foreground = c.fg,
	cursor_bg = c.fg,
	cursor_fg = c.bg,
	cursor_border = c.fg,
	selection_bg = c.bg_visual,
	selection_fg = c.fg,
	split = c.fg_gutter,
	compose_cursor = c.orange,

	ansi = {
		c.bg_dark,
		c.red,
		c.green,
		c.yellow,
		c.blue,
		c.magenta,
		c.cyan,
		c.fg_dark,
	},

	brights = {
		c.black,
		c.red_b,
		c.green_b,
		c.yellow_b,
		c.blue_b,
		c.magenta_b,
		c.cyan_b,
		c.fg,
	},

	indexed = {
		[16] = c.orange,
		[17] = c.red_dark,
	},

	tab_bar = {
		background = c.bg_dark,
		active_tab = { bg_color = c.bg, fg_color = c.blue, intensity = "Bold" },
		inactive_tab = { bg_color = c.bg_dark, fg_color = c.comment },
		inactive_tab_hover = { bg_color = c.bg_hl, fg_color = c.fg_dark },
		new_tab = { bg_color = c.bg_dark, fg_color = c.comment },
		new_tab_hover = { bg_color = c.bg_hl, fg_color = c.fg },
	},
}

-- ══════════════════════════════════════════════════════════════
--  Tab Bar
-- ══════════════════════════════════════════════════════════════

config.enable_tab_bar = true
config.tab_bar_at_bottom = false
config.use_fancy_tab_bar = false
config.show_new_tab_button_in_tab_bar = false
config.hide_tab_bar_if_only_one_tab = false
config.tab_max_width = 48
config.show_tab_index_in_tab_bar = false

-- ── Helpers ──────────────────────────────────────────────────

local function get_path_from_uri(uri)
	if not uri then
		return nil
	end
	if type(uri) == "userdata" and uri.file_path then
		return uri.file_path
	end

	local s = tostring(uri)
	local path = s:gsub("^file://[^/]*", "")
	path = path:gsub("%%(%x%x)", function(hex)
		return string.char(tonumber(hex, 16))
	end)
	return path ~= "" and path or nil
end

local function shorten_path(path)
	if not path or path == "" then
		return nil
	end

	local home = os.getenv("HOME")
	if home and path == home then
		return "~"
	end
	if home and path:sub(1, #home + 1) == home .. "/" then
		path = "~" .. path:sub(#home + 1)
	end

	local parts = {}
	for p in path:gmatch("[^/]+") do
		parts[#parts + 1] = p
	end

	if path:sub(1, 1) == "~" then
		if #parts <= 1 then
			return "~"
		end
		return "~/" .. parts[#parts - 1] .. "/" .. parts[#parts]
	end

	if #parts >= 2 then
		return parts[#parts - 1] .. "/" .. parts[#parts]
	end
	return parts[#parts] or path
end

local function get_cwd(tab)
	local pane = tab.active_pane
	if not pane then
		return "?"
	end

	local short = shorten_path(get_path_from_uri(pane.current_working_dir))
	if short and short ~= "" then
		return short
	end

	local proc = pane.foreground_process_name
	if proc and proc ~= "" then
		local name = proc:gsub(".*[/\\]", "")
		if name ~= "" then
			return name
		end
	end
	return "?"
end

-- ── Tab title formatter ──────────────────────────────────────

wezterm.on("format-tab-title", function(tab, _, _, _, _, max_width)
	local cwd = get_cwd(tab)
	local title = (tab.tab_title and #tab.tab_title > 0) and tab.tab_title or cwd

	local budget = math.max(8, math.min(max_width - 6, 40))
	if wezterm.column_width(title) > budget then
		title = wezterm.truncate_left(title, budget)
	end

	local tab_bg = tab.is_active and c.bg or c.bg_dark
	local tab_fg = tab.is_active and c.fg or c.comment
	local idx_fg = tab.is_active and c.blue or c.dark3
	local weight = tab.is_active and "Bold" or "Normal"

	return {
		{ Background = { Color = tab_bg } },
		{ Foreground = { Color = idx_fg } },
		{ Attribute = { Intensity = weight } },
		{ Text = " " .. tostring(tab.tab_index + 1) .. " " },

		{ Background = { Color = tab_bg } },
		{ Foreground = { Color = tab_fg } },
		{ Attribute = { Intensity = "Normal" } },
		{ Text = title .. " " },
	}
end)

-- ══════════════════════════════════════════════════════════════
--  Status Bar
-- ══════════════════════════════════════════════════════════════

local function git_branch(pane)
	local cwd = get_path_from_uri(pane:get_current_working_dir())
	if not cwd then
		return nil
	end

	local path = cwd
	for _ = 1, 8 do
		local f = io.open(path .. "/.git/HEAD", "r")
		if f then
			local head = f:read("*l") or ""
			f:close()
			return head:match("ref: refs/heads/(.+)") or head:sub(1, 7)
		end
		local parent = path:match("^(.*)/[^/]+$")
		if not parent or parent == path then
			break
		end
		path = parent
	end
	return nil
end

local bat_icons = {
	{ min = 80, icon = "󰁹", color = "green" },
	{ min = 60, icon = "󰂁", color = "green" },
	{ min = 40, icon = "󰁾", color = "yellow" },
	{ min = 20, icon = "󰁼", color = "orange" },
	{ min = 0, icon = "󰁺", color = "red" },
}
local bat_color_map = {
	green = c.green,
	yellow = c.yellow,
	orange = c.orange,
	red = c.red,
}

wezterm.on("update-status", function(window, pane)
	-- Left: workspace label + leader indicator
	local ws = window:active_workspace()
	local left = {
		{ Background = { Color = c.blue } },
		{ Foreground = { Color = c.bg_dark } },
		{ Attribute = { Intensity = "Bold" } },
		{ Text = "  " .. (ws == "default" and "default" or ws) .. "  " },
	}
	if window:leader_is_active() then
		left[#left + 1] = { Background = { Color = c.bg_hl } }
		left[#left + 1] = { Foreground = { Color = c.orange } }
		left[#left + 1] = { Text = " WAIT " }
	end
	window:set_left_status(wezterm.format(left))

	-- Right: git branch · battery · clock
	local right = {}

	local branch = git_branch(pane)
	if branch then
		right[#right + 1] = { Background = { Color = c.bg_hl } }
		right[#right + 1] = { Foreground = { Color = c.orange } }
		right[#right + 1] = { Text = " 󰊢 " }
		right[#right + 1] = { Foreground = { Color = c.fg_dark } }
		right[#right + 1] = { Text = branch .. " " }
	end

	local bat_info = wezterm.battery_info()
	if bat_info and #bat_info > 0 then
		local bat = bat_info[1]
		local pct = math.floor(bat.state_of_charge * 100 + 0.5)
		local charging = bat.state == "Charging" or bat.state == "Full"

		local icon, color_key
		if charging then
			icon, color_key = "󰂄", "green"
		else
			for _, tier in ipairs(bat_icons) do
				if pct >= tier.min then
					icon, color_key = tier.icon, tier.color
					break
				end
			end
		end

		right[#right + 1] = { Background = { Color = c.bg_hl } }
		right[#right + 1] = { Foreground = { Color = bat_color_map[color_key] or c.fg } }
		right[#right + 1] = { Text = " " .. icon .. " " }
		right[#right + 1] = { Foreground = { Color = c.fg_dark } }
		right[#right + 1] = { Text = pct .. "% " }
	end

	right[#right + 1] = { Background = { Color = c.blue } }
	right[#right + 1] = { Foreground = { Color = c.bg_dark } }
	right[#right + 1] = { Attribute = { Intensity = "Bold" } }
	right[#right + 1] = { Text = " 󰥔 " .. wezterm.strftime("%H:%M") .. " " }

	window:set_right_status(wezterm.format(right))
end)

-- ══════════════════════════════════════════════════════════════
--  Hyperlink Rules
-- ══════════════════════════════════════════════════════════════

-- Minimal set: Neovim handles most links/files with gx/gF.
config.hyperlink_rules = {
	{ regex = [[\bfile://\S*\b]], format = "$0" },
	{ regex = [[\b(?:localhost|127\.0\.0\.1|0\.0\.0\.0):[0-9]{2,5}\S*\b]], format = "http://$0" },
}

-- ══════════════════════════════════════════════════════════════
--  Mouse Bindings
-- ══════════════════════════════════════════════════════════════

config.mouse_bindings = {
	-- Mouse-up copies selection to clipboard then clears highlight (or opens link)
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "NONE",
		action = act.Multiple({
			act.CompleteSelectionOrOpenLinkAtMouseCursor("Clipboard"),
			act.ClearSelection,
		}),
	},
	-- Ctrl+click opens links
	{ event = { Up = { streak = 1, button = "Left" } }, mods = "CTRL", action = act.OpenLinkAtMouseCursor },
	{ event = { Down = { streak = 1, button = "Left" } }, mods = "CTRL", action = act.Nop },

	-- Right-click pastes clipboard; middle-click pastes primary
	{ event = { Down = { streak = 1, button = "Right" } }, mods = "NONE", action = act.PasteFrom("Clipboard") },
	{ event = { Down = { streak = 1, button = "Middle" } }, mods = "NONE", action = act.PasteFrom("PrimarySelection") },

	-- Ctrl+scroll adjusts font size
	{ event = { Down = { streak = 1, button = { WheelUp = 1 } } }, mods = "CTRL", action = act.IncreaseFontSize },
	{ event = { Down = { streak = 1, button = { WheelDown = 1 } } }, mods = "CTRL", action = act.DecreaseFontSize },
}

-- ══════════════════════════════════════════════════════════════
--  Key Bindings — tmux-like leader workflow
-- ══════════════════════════════════════════════════════════════

config.leader = { key = "`", mods = "NONE", timeout_milliseconds = 1000 }
config.disable_default_key_bindings = true

-- ── Helpers ──────────────────────────────────────────────────

local function is_vim(pane)
	return (pane:get_foreground_process_name() or ""):find("n?vim") ~= nil
end

local pane_dir = { h = "Left", j = "Down", k = "Up", l = "Right" }

local function leader_nav(key)
	return {
		key = key,
		mods = "LEADER",
		action = wezterm.action_callback(function(win, pane)
			if is_vim(pane) then
				win:perform_action(act.SendKey({ key = key, mods = "LEADER" }), pane)
			else
				win:perform_action(act.ActivatePaneDirection(pane_dir[key]), pane)
			end
		end),
	}
end

local function resize(key, direction)
	return { key = key, mods = "LEADER", action = act.AdjustPaneSize({ direction, 5 }) }
end

local function tab(index)
	return { key = tostring(index), mods = "LEADER", action = act.ActivateTab(index - 1) }
end

-- ── Keys table ──────────────────────────────────────────────

config.keys = {
	-- Misc
	{ key = "`", mods = "LEADER", action = act.SendKey({ key = "`" }) },
	{
		key = "r",
		mods = "LEADER",
		action = wezterm.action_callback(function(win, pane)
			win:perform_action(act.ReloadConfiguration, pane)
			win:toast_notification("WezTerm", "Config reloaded", nil, 2000)
		end),
	},

	-- Tabs
	{ key = "c", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "n", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "q", mods = "LEADER", action = act.CloseCurrentPane({ confirm = false }) },
	{ key = "Q", mods = "LEADER", action = act.CloseCurrentTab({ confirm = false }) },
	{
		key = ",",
		mods = "LEADER",
		action = act.PromptInputLine({
			description = "Rename tab:",
			action = wezterm.action_callback(function(win, _, line)
				if line then
					win:active_tab():set_title(line)
				end
			end),
		}),
	},
	{
		key = "e",
		mods = "LEADER",
		action = act.PromptInputLine({
			description = "Rename tab:",
			action = wezterm.action_callback(function(win, _, line)
				if line then
					win:active_tab():set_title(line)
				end
			end),
		}),
	},

	-- Splits
	{ key = '"', mods = "LEADER|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "%", mods = "LEADER|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "H", mods = "LEADER|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "|", mods = "LEADER|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "V", mods = "LEADER|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "-", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },

	-- Pane navigation (vim-aware)
	leader_nav("h"),
	leader_nav("j"),
	leader_nav("k"),
	leader_nav("l"),

	-- Pane resize
	resize("LeftArrow", "Left"),
	resize("RightArrow", "Right"),
	resize("UpArrow", "Up"),
	resize("DownArrow", "Down"),

	-- Pane utilities
	{ key = "z", mods = "LEADER", action = act.TogglePaneZoomState },
	{ key = "s", mods = "LEADER", action = act.PaneSelect({ mode = "SwapWithActive" }) },
	{ key = "p", mods = "LEADER", action = act.PaneSelect({}) },
	{ key = "o", mods = "LEADER", action = act.ActivatePaneDirection("Next") },

	-- Tab navigation
	{ key = "Tab", mods = "LEADER", action = act.ActivateLastTab },
	{ key = "h", mods = "LEADER|CTRL", action = act.ActivateTabRelative(-1) },
	{ key = "l", mods = "LEADER|CTRL", action = act.ActivateTabRelative(1) },
	{ key = "{", mods = "LEADER|SHIFT", action = act.MoveTabRelative(-1) },
	{ key = "}", mods = "LEADER|SHIFT", action = act.MoveTabRelative(1) },

	tab(1),
	tab(2),
	tab(3),
	tab(4),
	tab(5),
	tab(6),
	tab(7),
	tab(8),
	tab(9),

	-- Tab bar toggle
	{
		key = "S",
		mods = "LEADER|SHIFT",
		action = wezterm.action_callback(function(win)
			local overrides = win:get_config_overrides() or {}
			overrides.enable_tab_bar = not (overrides.enable_tab_bar == false)
			win:set_config_overrides(overrides)
		end),
	},

	-- Workspaces
	{ key = "w", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "WORKSPACES" }) },
	{
		key = "W",
		mods = "LEADER|SHIFT",
		action = act.PromptInputLine({
			description = "New workspace name:",
			action = wezterm.action_callback(function(win, _, line)
				if line and #line > 0 then
					win:perform_action(act.SwitchToWorkspace({ name = line }), win:active_pane())
				end
			end),
		}),
	},
	{ key = "(", mods = "LEADER|SHIFT", action = act.SwitchWorkspaceRelative(-1) },
	{ key = ")", mods = "LEADER|SHIFT", action = act.SwitchWorkspaceRelative(1) },
	{
		key = "$",
		mods = "LEADER|SHIFT",
		action = wezterm.action_callback(function(win, pane)
			local cur = win:active_workspace()
			win:perform_action(
				act.PromptInputLine({
					description = 'Rename workspace "' .. cur .. '" to:',
					initial_value = cur,
					action = wezterm.action_callback(function(w, _, line)
						if line and #line > 0 and line ~= cur then
							wezterm.mux.rename_workspace(cur, line)
						end
					end),
				}),
				pane
			)
		end),
	},

	-- Copy / search / paste
	{ key = "c", mods = "CTRL|SHIFT", action = act.CopyTo("Clipboard") },
	{ key = "v", mods = "CTRL|SHIFT", action = act.PasteFrom("Clipboard") },
	{ key = "v", mods = "LEADER", action = act.PasteFrom("PrimarySelection") },
	{ key = "[", mods = "LEADER", action = act.ActivateCopyMode },
	{ key = "y", mods = "LEADER", action = act.ActivateCopyMode },
	{ key = "f", mods = "CTRL|SHIFT", action = act.Search({ CaseSensitiveString = "" }) },
	{ key = "P", mods = "CTRL|SHIFT", action = act.ActivateCommandPalette },

	-- Scrollback
	{ key = "u", mods = "CTRL|SHIFT", action = act.ScrollByPage(-0.5) },
	{ key = "d", mods = "CTRL|SHIFT", action = act.ScrollByPage(0.5) },
	{ key = "PageUp", mods = "SHIFT", action = act.ScrollByPage(-1) },
	{ key = "PageDown", mods = "SHIFT", action = act.ScrollByPage(1) },
	{ key = "Home", mods = "SHIFT", action = act.ScrollToTop },
	{ key = "End", mods = "SHIFT", action = act.ScrollToBottom },

	-- Font / window
	{ key = "=", mods = "CTRL", action = act.IncreaseFontSize },
	{ key = "-", mods = "CTRL", action = act.DecreaseFontSize },
	{ key = "0", mods = "CTRL", action = act.ResetFontSize },
	{ key = "F11", mods = "NONE", action = act.ToggleFullScreen },
	{ key = "l", mods = "CTRL|SHIFT", action = act.ClearScrollback("ScrollbackAndViewport") },
	{ key = ".", mods = "LEADER", action = act.ShowDebugOverlay },
}

-- ══════════════════════════════════════════════════════════════
--  Copy & Search Modes (vim-like)
-- ══════════════════════════════════════════════════════════════

config.key_tables = {
	copy_mode = {
		{ key = "h", mods = "NONE", action = act.CopyMode("MoveLeft") },
		{ key = "j", mods = "NONE", action = act.CopyMode("MoveDown") },
		{ key = "k", mods = "NONE", action = act.CopyMode("MoveUp") },
		{ key = "l", mods = "NONE", action = act.CopyMode("MoveRight") },
		{ key = "w", mods = "NONE", action = act.CopyMode("MoveForwardWord") },
		{ key = "b", mods = "NONE", action = act.CopyMode("MoveBackwardWord") },
		{ key = "e", mods = "NONE", action = act.CopyMode("MoveForwardWordEnd") },
		{ key = "0", mods = "NONE", action = act.CopyMode("MoveToStartOfLine") },
		{ key = "$", mods = "NONE", action = act.CopyMode("MoveToEndOfLineContent") },
		{ key = "g", mods = "NONE", action = act.CopyMode("MoveToScrollbackTop") },
		{ key = "G", mods = "NONE", action = act.CopyMode("MoveToScrollbackBottom") },
		{ key = "u", mods = "CTRL", action = act.CopyMode({ MoveByPage = -0.5 }) },
		{ key = "d", mods = "CTRL", action = act.CopyMode({ MoveByPage = 0.5 }) },

		{ key = "v", mods = "NONE", action = act.CopyMode({ SetSelectionMode = "Cell" }) },
		{ key = "V", mods = "NONE", action = act.CopyMode({ SetSelectionMode = "Line" }) },
		{ key = "v", mods = "CTRL", action = act.CopyMode({ SetSelectionMode = "Block" }) },

		{
			key = "y",
			mods = "NONE",
			action = act.Multiple({ { CopyTo = "ClipboardAndPrimarySelection" }, { CopyMode = "Close" } }),
		},
		{
			key = "Enter",
			mods = "NONE",
			action = act.Multiple({ { CopyTo = "ClipboardAndPrimarySelection" }, { CopyMode = "Close" } }),
		},
		{ key = "Escape", mods = "NONE", action = act.CopyMode("Close") },
		{ key = "q", mods = "NONE", action = act.CopyMode("Close") },

		{ key = "/", mods = "NONE", action = act.Search({ CaseSensitiveString = "" }) },
		{ key = "n", mods = "NONE", action = act.CopyMode("NextMatch") },
		{ key = "N", mods = "NONE", action = act.CopyMode("PriorMatch") },
	},

	search_mode = {
		{ key = "Escape", mods = "NONE", action = act.CopyMode("Close") },
		{ key = "Enter", mods = "NONE", action = act.CopyMode("PriorMatch") },
		{ key = "n", mods = "CTRL", action = act.CopyMode("NextMatch") },
		{ key = "p", mods = "CTRL", action = act.CopyMode("PriorMatch") },
		{ key = "r", mods = "CTRL", action = act.CopyMode("CycleMatchType") },
		{ key = "u", mods = "CTRL", action = act.CopyMode("ClearPattern") },
	},
}

return config
