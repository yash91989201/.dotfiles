vim.g.mapleader = " "

local keymap = vim.keymap

keymap.set("i", "jk", "<ESC>", { desc = "Exit insert mode" })

keymap.set("n", "x", '"_x')

keymap.set("n", "+", "<C-a>", { desc = "Increment number" })
keymap.set("n", "-", "<C-x>", { desc = "Decrement number" })

keymap.set("n", "<leader>bs", ":w<Return>", { desc = "Save current buffer", noremap = true, silent = true })
keymap.set("n", "<leader>bS", ":wa!<Return>", { desc = "Save all buffers", noremap = true, silent = true })
