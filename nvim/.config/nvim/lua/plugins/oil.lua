return {
  "stevearc/oil.nvim",
  dependencies = { "echasnovski/mini.icons" },
  opts = {
    keymaps = {
      ["<CR>"] = false,
      ["<C-t>"] = false,
      ["<C-s>"] = false,
      ["<C-h>"] = false,
      ["-"] = false,
      ["gs"] = false,
      ["gx"] = false,
      ["<M-s>"] = { "actions.select", opts = { vertical = true }, desc = "Open file in vertical split" },
      ["<M-h>"] = { "actions.select", opts = { horizontal = true }, desc = "Open file in horizontal split" },
      ["q"] = "actions.close",
      ["h"] = "actions.parent",
      ["l"] = "actions.select",
    },
    view_options = {
      show_hidden = true,
      is_always_hidden = function(name, _)
        local folder_skip = { ".next", "node_modules", "dev-tools.locks", "dune.lock", "_build", ".git", ".." }
        return vim.tbl_contains(folder_skip, name)
      end,
    },
    float = {
      max_width = 0.75,
      max_height = 0.75,
    },
  },
  keys = {
    { "<leader>fO", "<CMD>Oil<CR>", desc = "Open Oil Explorer" },
    { "<leader>fo", "<CMD>Oil --float<CR>", desc = "Open Oil Explorer (floating)" },
  },
}
