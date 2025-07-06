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
    provider = "claude-3.5-sonnet",
    providers = {
      copilot = {
        hide_in_model_selector = true,
      },
      gemini = {
        hide_in_model_selector = true,
      },
      ["claude-3.5-sonnet"] = {
        __inherited_from = "copilot",
        model = "claude-3.5-sonnet",
        display_name = "copilot/claude-3.5-sonnet",
        hide_in_model_selector = false,
      },
      ["gpt-4"] = {
        __inherited_from = "copilot",
        model = "gpt-4",
        display_name = "copilot/gpt-4",
        hide_in_model_selector = false,
      },
      ["gpt-4.1"] = {
        __inherited_from = "copilot",
        model = "gpt-4.1",
        display_name = "copilot/gpt-4.1",
        hide_in_model_selector = false,
      },
      ["gpt-4o"] = {
        __inherited_from = "copilot",
        model = "gpt-4o",
        display_name = "copilot/gpt-4o",
        hide_in_model_selector = false,
      },
      ["gpt-4o-mini"] = {
        __inherited_from = "copilot",
        model = "gpt-4o-mini",
        display_name = "copilot/gpt-4o-mini",
        hide_in_model_selector = false,
      },
      ["o3-mini"] = {
        __inherited_from = "copilot",
        model = "o3-mini",
        display_name = "copilot/o3-mini",
        hide_in_model_selector = false,
      },
      ["openai"] = {
        model = "gpt-4o",
        display_name = "openai/gpt-4o",
      },
      ["openai-gpt-4o-mini"] = {
        model = "gpt-4o-mini",
        display_name = "openai/gpt-4o-mini",
      },
      gemini_pro = {
        __inherited_from = "gemini",
        display_name = "gemini/gemini-2.5-pro",
        model = "gemini-2.5-pro",
        hide_in_model_selector = false,
        extra_request_body = {
          temperature = 0,
        },
      },
      gemini_flash = {
        __inherited_from = "gemini",
        display_name = "gemini/gemini-2.5-flash",
        model = "gemini-2.5-flash",
        hide_in_model_selector = false,
        extra_request_body = {
          temperature = 0,
        },
      },
      gemini_flash_lite = {
        __inherited_from = "gemini",
        display_name = "gemini/gemini-2.5-flash-lite",
        model = "gemini-2.5-flash-lite-preview-06-17",
        hide_in_model_selector = false,
        extra_request_body = {
          temperature = 0,
        },
      },
      vertex = {
        hide_in_model_selector = true,
      },
      vertex_claude = {
        hide_in_model_selector = true,
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
    windows = {
      width = 36,
      input = {
        height = 10,
      },
    },
    input = {
      provider = "snacks",
    },
    selector = {
      provider = "snacks",
    },
  },
  keys = {
    { "<leader>ax", "<cmd>AvanteClear<cr>", desc = "avante: clear chat" },
  },
}
