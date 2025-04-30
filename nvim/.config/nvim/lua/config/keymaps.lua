vim.g.mapleader = " "

local keymap = vim.keymap

keymap.set("i", "jk", "<ESC>", { desc = "Exit insert mode with jk" })

keymap.set("n", "<leader>ch", ":nohl<CR>", { desc = "Clear search highlights" })

keymap.set("n", "x", '"_x')

-- Increment/decrement
keymap.set("n", "+", "<C-a>")
keymap.set("n", "-", "<C-x>")

-- Select all
keymap.set("n", "<C-a>", "gg<S-v>G")

keymap.set("n", "<leader>mq", ":wqa!<Return>", { desc = "Save and quit all", noremap = true, silent = true })
keymap.set("n", "<leader>ms", ":wa!<Return>", { desc = "Save all", noremap = true, silent = true })
