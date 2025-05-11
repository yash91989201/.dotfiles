vim.g.mapleader = " "

local keymap = vim.keymap

keymap.set("i", "jk", "<ESC>", { desc = "Exit insert mode" })

keymap.set("n", "x", '"_x')

keymap.set("n", "+", "<C-a>", { desc = "Increment number" })
keymap.set("n", "-", "<C-x>", { desc = "Decrement number" })

keymap.set("n", "<C-a>", "ggVG", { desc = "Select all" })

keymap.set("n", "<leader>mq", ":wqa!<Return>", { desc = "Save and quit all", noremap = true, silent = true })
keymap.set("n", "<leader>ms", ":wa!<Return>", { desc = "Save all", noremap = true, silent = true })
