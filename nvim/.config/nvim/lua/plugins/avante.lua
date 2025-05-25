return {
  "yetone/avante.nvim",
  event = "VeryLazy",
  version = false,
  build = "make",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "stevearc/dressing.nvim",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "echasnovski/mini.icons",
    "folke/snacks.nvim",
    {
      "MeanderingProgrammer/render-markdown.nvim",
      opts = {
        file_types = { "markdown", "Avante" },
      },
      ft = { "markdown", "Avante" },
    },
  },
  opts = {
    provider = "gemini",
    behaviour = {
      auto_suggestions = false,
      auto_set_highlight_group = true,
      auto_set_keymaps = true,
      auto_apply_diff_after_generation = false,
      support_paste_from_clipboard = true,
    },
    gemini = {
      -- model = "gemini-2.0-flash",
      model = "gemini-2.5-pro-preview-05-06",
      temperature = 0,
      max_tokens = 4096,
    },
    selector = {
      provider = "snacks",
    },
    windows = {
      position = "bottom",
      height = 40,
    },
  },
  keys = {
    { "<leader>aC", "<cmd>AvanteClear<cr>", desc = "avante: clear" },
  },
}
