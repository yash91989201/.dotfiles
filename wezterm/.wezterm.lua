local wezterm = require("wezterm")
local act = wezterm.action
local mux = wezterm.mux

local config = wezterm.config_builder()

-- ============================================================
-- TokyoNight Palette
-- ============================================================

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

	blue_b = "#8db0ff",
	cyan_b = "#a4daff",
	green_b = "#9fe044",
	yellow_b = "#faba4a",
	magenta_b = "#c7a9ff",
	red_b = "#ff899d",
}

-- ============================================================
-- General
-- ============================================================

config.enable_wayland = false
config.check_for_updates = false
config.show_update_window = false
config.warn_about_missing_glyphs = false
config.audible_bell = "Disabled"

config.window_close_confirmation = "NeverPrompt"
config.skip_close_confirmation_for_processes_named = {
	"bash",
	"zsh",
	"fish",
	"sh",
	"nu",
}

-- ============================================================
-- Window
-- ============================================================

config.window_decorations = "NONE"
config.window_background_opacity = 1.0
config.initial_cols = 120
config.initial_rows = 30
config.enable_scroll_bar = false
config.scrollback_lines = 10000

config.window_padding = {
	left = 8,
	right = 8,
	top = 6,
	bottom = 0,
}

config.inactive_pane_hsb = {
	saturation = 0.95,
	brightness = 0.8,
}

wezterm.on("gui-startup", function()
	local _, _, window = mux.spawn_window({})
	window:gui_window():maximize()
end)

-- ============================================================
-- Font
-- ============================================================

config.font = wezterm.font_with_fallback({
	{ family = "JetBrainsMono Nerd Font Mono", weight = "Medium" },
	{ family = "JetBrains Mono", weight = "Medium" },
	{ family = "Symbols Nerd Font Mono" },
	{ family = "Noto Color Emoji" },
})

config.font_size = 11
config.line_height = 1.1
config.cell_width = 1.0

config.freetype_load_target = "Normal"
config.freetype_render_target = "HorizontalLcd"

config.underline_position = -3
config.underline_thickness = 1

-- ============================================================
-- Colors
-- ============================================================

config.colors = {
	background = c.bg,
	foreground = c.fg,
	cursor_bg = c.fg,
	cursor_fg = c.bg,
	cursor_border = c.fg,

	selection_bg = c.bg_hl,
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

		active_tab = {
			bg_color = c.bg,
			fg_color = c.blue,
			intensity = "Bold",
		},
		inactive_tab = {
			bg_color = c.bg_dark,
			fg_color = c.comment,
		},
		inactive_tab_hover = {
			bg_color = c.bg_hl,
			fg_color = c.fg_dark,
		},
		new_tab = {
			bg_color = c.bg_dark,
			fg_color = c.comment,
		},
		new_tab_hover = {
			bg_color = c.bg_hl,
			fg_color = c.fg,
		},
	},
}

-- ============================================================
-- Tab bar
-- ============================================================

config.tab_bar_at_bottom = false
config.use_fancy_tab_bar = false
config.show_new_tab_button_in_tab_bar = false
config.hide_tab_bar_if_only_one_tab = false
config.tab_max_width = 40
config.show_tab_index_in_tab_bar = false

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

	if path == "" then
		return nil
	end

	return path
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
		table.insert(parts, p)
	end

	if path:sub(1, 1) == "~" then
		if #parts == 1 then
			return "~"
		elseif #parts >= 2 then
			return "~/" .. parts[#parts - 1] .. "/" .. parts[#parts]
		end
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

	local path = get_path_from_uri(pane.current_working_dir)
	local short = shorten_path(path)
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

	return {
		{ Background = { Color = tab_bg } },
		{ Foreground = { Color = idx_fg } },
		{ Attribute = { Intensity = tab.is_active and "Bold" or "Normal" } },
		{ Text = " " .. tostring(tab.tab_index + 1) .. " " },

		{ Background = { Color = tab_bg } },
		{ Foreground = { Color = tab_fg } },
		{ Attribute = { Intensity = "Normal" } },
		{ Text = title .. " " },
	}
end)

-- ============================================================
-- Status bar
-- ============================================================

local function git_branch(pane)
	local cwd_uri = pane:get_current_working_dir()
	if not cwd_uri then
		return nil
	end

	local cwd = get_path_from_uri(cwd_uri)
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

wezterm.on("update-status", function(window, pane)
	local left = {}

	local ws = window:active_workspace()
	local ws_label = (ws == "default") and "default" or ws

	table.insert(left, { Background = { Color = c.blue } })
	table.insert(left, { Foreground = { Color = c.bg_dark } })
	table.insert(left, { Attribute = { Intensity = "Bold" } })
	table.insert(left, { Text = "  " .. ws_label .. "  " })

	if window:leader_is_active() then
		table.insert(left, { Background = { Color = c.bg_dark } })
		table.insert(left, { Foreground = { Color = c.orange } })
		table.insert(left, { Text = " WAIT " })
	end

	window:set_left_status(wezterm.format(left))

	local right = {}

	-- git branch first
	local branch = git_branch(pane)
	if branch then
		table.insert(right, { Background = { Color = c.bg_hl } })
		table.insert(right, { Foreground = { Color = c.orange } })
		table.insert(right, { Text = " 󰊢 " })
		table.insert(right, { Foreground = { Color = c.fg_dark } })
		table.insert(right, { Text = branch .. " " })
	end

	-- battery second
	local bat_info = wezterm.battery_info()
	if bat_info and #bat_info > 0 then
		local bat = bat_info[1]
		local pct = math.floor(bat.state_of_charge * 100 + 0.5)

		local bat_icon, bat_color
		local charging = bat.state == "Charging" or bat.state == "Full"

		if charging then
			bat_icon = "󰂄"
			bat_color = c.green
		elseif pct >= 80 then
			bat_icon = "󰁹"
			bat_color = c.green
		elseif pct >= 60 then
			bat_icon = "󰂁"
			bat_color = c.green
		elseif pct >= 40 then
			bat_icon = "󰁾"
			bat_color = c.yellow
		elseif pct >= 20 then
			bat_icon = "󰁼"
			bat_color = c.orange
		else
			bat_icon = "󰁺"
			bat_color = c.red
		end

		table.insert(right, { Background = { Color = c.bg_hl } })
		table.insert(right, { Foreground = { Color = bat_color } })
		table.insert(right, { Text = " " .. bat_icon .. " " })
		table.insert(right, { Foreground = { Color = c.fg_dark } })
		table.insert(right, { Text = pct .. "% " })
	end

	-- time last
	table.insert(right, { Background = { Color = c.blue } })
	table.insert(right, { Foreground = { Color = c.bg_dark } })
	table.insert(right, { Attribute = { Intensity = "Bold" } })
	table.insert(right, { Text = " 󰥔 " .. wezterm.strftime("%H:%M") .. " " })

	window:set_right_status(wezterm.format(right))
end)

-- Hyprland/Wayland specific fixes
config.enable_wayland = false
config.window_decorations = "NONE"

-- ============================================================
-- Hyperlinks
-- ============================================================

config.hyperlink_rules = wezterm.default_hyperlink_rules()

table.insert(config.hyperlink_rules, {
	regex = [[\bfile://\S*\b]],
	format = "$0",
})

table.insert(config.hyperlink_rules, {
	regex = [[\b(?:localhost|127\.0\.0\.1|0\.0\.0\.0):[0-9]{2,5}\S*\b]],
	format = "http://$0",
})

-- ============================================================
-- Mouse
-- ============================================================

config.mouse_bindings = {
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "CTRL",
		action = act.OpenLinkAtMouseCursor,
	},
	{
		event = { Down = { streak = 1, button = "Left" } },
		mods = "CTRL",
		action = act.Nop,
	},

	{
		event = { Down = { streak = 1, button = "Right" } },
		mods = "NONE",
		action = act.PasteFrom("Clipboard"),
	},
	{
		event = { Down = { streak = 1, button = "Middle" } },
		mods = "NONE",
		action = act.PasteFrom("PrimarySelection"),
	},
	{
		event = { Down = { streak = 1, button = { WheelUp = 1 } } },
		mods = "CTRL",
		action = act.IncreaseFontSize,
	},
	{
		event = { Down = { streak = 1, button = { WheelDown = 1 } } },
		mods = "CTRL",
		action = act.DecreaseFontSize,
	},
}

-- ============================================================
-- Keybindings
-- ============================================================

config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 }
config.disable_default_key_bindings = true

local function is_vim(pane)
	return (pane:get_foreground_process_name() or ""):find("n?vim") ~= nil
end

local dir = { h = "Left", j = "Down", k = "Up", l = "Right" }

local function nav(resize, key)
	local mods = resize and "ALT|SHIFT" or "ALT"
	return {
		key = key,
		mods = mods,
		action = wezterm.action_callback(function(win, pane)
			if is_vim(pane) then
				win:perform_action(act.SendKey({ key = key, mods = mods }), pane)
			elseif resize then
				win:perform_action(act.AdjustPaneSize({ dir[key], 3 }), pane)
			else
				win:perform_action(act.ActivatePaneDirection(dir[key]), pane)
			end
		end),
	}
end

config.keys = {
	nav(false, "h"),
	nav(false, "j"),
	nav(false, "k"),
	nav(false, "l"),

	nav(true, "h"),
	nav(true, "j"),
	nav(true, "k"),
	nav(true, "l"),

	{ key = "\\", mods = "ALT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "-", mods = "ALT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{
		key = "|",
		mods = "ALT|SHIFT",
		action = act.SplitPane({ top_level = true, direction = "Right", size = { Percent = 50 } }),
	},
	{
		key = "_",
		mods = "ALT|SHIFT",
		action = act.SplitPane({ top_level = true, direction = "Down", size = { Percent = 50 } }),
	},

	{ key = "q", mods = "ALT", action = act.CloseCurrentPane({ confirm = false }) },
	{ key = "z", mods = "ALT", action = act.TogglePaneZoomState },
	{ key = "r", mods = "ALT", action = act.RotatePanes("Clockwise") },
	{ key = "s", mods = "ALT", action = act.PaneSelect({ mode = "SwapWithActive" }) },
	{ key = "p", mods = "ALT", action = act.PaneSelect({}) },

	{ key = "t", mods = "CTRL|SHIFT", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "n", mods = "ALT", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "Q", mods = "ALT", action = act.CloseCurrentTab({ confirm = false }) },
	{ key = "[", mods = "ALT", action = act.ActivateTabRelative(-1) },
	{ key = "]", mods = "ALT", action = act.ActivateTabRelative(1) },
	{ key = "{", mods = "ALT|SHIFT", action = act.MoveTabRelative(-1) },
	{ key = "}", mods = "ALT|SHIFT", action = act.MoveTabRelative(1) },

	{ key = "1", mods = "ALT", action = act.ActivateTab(0) },
	{ key = "2", mods = "ALT", action = act.ActivateTab(1) },
	{ key = "3", mods = "ALT", action = act.ActivateTab(2) },
	{ key = "4", mods = "ALT", action = act.ActivateTab(3) },
	{ key = "5", mods = "ALT", action = act.ActivateTab(4) },
	{ key = "6", mods = "ALT", action = act.ActivateTab(5) },
	{ key = "7", mods = "ALT", action = act.ActivateTab(6) },
	{ key = "8", mods = "ALT", action = act.ActivateTab(7) },
	{ key = "9", mods = "ALT", action = act.ActivateTab(8) },

	{
		key = "e",
		mods = "ALT",
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
		key = "w",
		mods = "LEADER",
		action = act.ShowLauncherArgs({ flags = "WORKSPACES" }),
	},
	{
		key = "W",
		mods = "LEADER",
		action = act.PromptInputLine({
			description = "New workspace name:",
			action = wezterm.action_callback(function(win, _, line)
				if line and #line > 0 then
					win:perform_action(act.SwitchToWorkspace({ name = line }), win:active_pane())
				end
			end),
		}),
	},

	{ key = "c", mods = "CTRL|SHIFT", action = act.CopyTo("Clipboard") },
	{ key = "v", mods = "CTRL|SHIFT", action = act.PasteFrom("Clipboard") },
	{ key = "v", mods = "LEADER", action = act.PasteFrom("PrimarySelection") },

	{ key = "y", mods = "ALT", action = act.ActivateCopyMode },
	{ key = "f", mods = "CTRL|SHIFT", action = act.Search({ CaseSensitiveString = "" }) },

	{ key = "P", mods = "CTRL|SHIFT", action = act.ActivateCommandPalette },

	{ key = "u", mods = "CTRL|SHIFT", action = act.ScrollByPage(-0.5) },
	{ key = "d", mods = "CTRL|SHIFT", action = act.ScrollByPage(0.5) },
	{ key = "PageUp", mods = "SHIFT", action = act.ScrollByPage(-1) },
	{ key = "PageDown", mods = "SHIFT", action = act.ScrollByPage(1) },
	{ key = "Home", mods = "SHIFT", action = act.ScrollToTop },
	{ key = "End", mods = "SHIFT", action = act.ScrollToBottom },

	{ key = "=", mods = "CTRL", action = act.IncreaseFontSize },
	{ key = "-", mods = "CTRL", action = act.DecreaseFontSize },
	{ key = "0", mods = "CTRL", action = act.ResetFontSize },

	{ key = "F11", mods = "", action = act.ToggleFullScreen },
	{ key = "l", mods = "CTRL|SHIFT", action = act.ClearScrollback("ScrollbackAndViewport") },
	{ key = ".", mods = "LEADER", action = act.ShowDebugOverlay },

	{
		key = "S",
		mods = "ALT",
		action = wezterm.action_callback(function(win)
			local overrides = win:get_config_overrides() or {}

			overrides.enable_tab_bar = not (overrides.enable_tab_bar == false)

			if overrides.enable_tab_bar == false then
				overrides.window_padding = { left = 8, right = 8, top = 6, bottom = 0 }
			else
				overrides.window_padding = nil
			end

			win:set_config_overrides(overrides)
		end),
	},
}

-- ============================================================
-- Copy mode
-- ============================================================

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
