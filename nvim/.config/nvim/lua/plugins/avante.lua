return {
  "yetone/avante.nvim",
  event = "VeryLazy",
  version = false,
  build = "make",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
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
    providers = {
      gemini = {
        -- model = "gemini-2.5-flash",
        model = "gemini-2.5-pro",
        extra_request_body = {
          temperature = 0.25,
        },
      },
    },
    behaviour = {
      auto_set_keymaps = true,
      auto_suggestions = false,
      auto_set_highlight_group = true,
      support_paste_from_clipboard = true,
      auto_apply_diff_after_generation = false,
    },
    system_prompt = function()
      local hub = require("mcphub").get_hub_instance()
      return hub and hub:get_active_servers_prompt() or ""
    end,
    custom_tools = function()
      return {
        require("mcphub.extensions.avante").mcp_tool(),
      }
    end,
    input = {
      provider = "snacks",
    },
    selector = {
      provider = "snacks",
    },
    windows = {
      width = 38,
    },
  },
  keys = {
    { "<leader>ax", "<cmd>AvanteClear<cr>", desc = "avante: clear chat" },
  },
}
