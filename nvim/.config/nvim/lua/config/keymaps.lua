vim.g.mapleader = " "

local keymap = vim.keymap

keymap.set("i", "jk", "<ESC>", { desc = "Exit insert mode" })

keymap.set("n", "x", '"_x')

keymap.set("n", "+", "<C-a>", { desc = "Increment number" })
keymap.set("n", "-", "<C-x>", { desc = "Decrement number" })

keymap.set("n", "<leader>bs", ":w<Return>", { desc = "Save current buffer", noremap = true, silent = true })
keymap.set("n", "<leader>bS", ":wa!<Return>", { desc = "Save all buffers", noremap = true, silent = true })

-- Split terminals instead of LazyVim's floating ones.
-- Snacks keys a terminal by cmd/cwd/env/count only (not position), so each
-- orientation needs its own `count` to stay a separate, persistent instance.
keymap.set("n", "<leader>ft", function()
  Snacks.terminal.toggle(nil, {
    count = 1,
    cwd = LazyVim.root(),
    win = { position = "right", width = 0.25 },
  })
end, { desc = "Terminal Right (Root Dir)" })

keymap.set("n", "<leader>fT", function()
  Snacks.terminal.toggle(nil, {
    count = 2,
    cwd = LazyVim.root(),
    win = { position = "bottom", height = 0.25 },
  })
end, { desc = "Terminal Bottom (Root Dir)" })

-- <C-/> keeps a floating terminal. It still needs its own explicit count:
-- snacks keys terminals by cmd/cwd/env/count only (not position), so without
-- count=3 it would collide with the right (1) or bottom (2) terminal's id.
local function focus_float()
  Snacks.terminal.focus(nil, {
    count = 3,
    cwd = LazyVim.root(),
    win = { position = "float" },
  })
end
keymap.set({ "n", "t" }, "<c-/>", focus_float, { desc = "Terminal Float (Root Dir)" })
keymap.set({ "n", "t" }, "<c-_>", focus_float, { desc = "which_key_ignore" })
