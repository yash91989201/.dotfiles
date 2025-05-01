return {
  "stevearc/oil.nvim",
  dependencies = { "echasnovski/mini.icons" },
  config = function()
    CustomOilBar = function()
      local path = vim.fn.expand("%")
      path = path:gsub("oil://", "")

      return "  " .. vim.fn.fnamemodify(path, ":.")
    end

    require("oil").setup({
      columns = { "icon" },
      keymaps = {
        ["<C-h>"] = false,
        ["<C-l>"] = false,
        ["<C-k>"] = false,
        ["<C-j>"] = false,
        ["<M-h>"] = "actions.select_split",
      },
      win_options = {
        winbar = "%{v:lua.CustomOilBar()}",
      },
      view_options = {
        show_hidden = true,
        is_always_hidden = function(name, _)
          local folder_skip = { ".next", "node_modules", "dev-tools.locks", "dune.lock", "_build" }
          return vim.tbl_contains(folder_skip, name)
        end,
      },

      float = {
        max_width = 0.8,
        max_height = 0.8,
      },
    })

    vim.keymap.set("n", "<leader>oo", "<CMD>Oil<CR>", { desc = "Open parent directory in current window" })

    vim.keymap.set(
      "n",
      "<leader>of",
      require("oil").toggle_float,
      { desc = "Open parent directory in floating window" }
    )
  end,
}
