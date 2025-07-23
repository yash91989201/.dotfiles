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
    provider = "copilot-gpt-4.1",
    providers = {
      morph = {
        model = "morph-v3-fast",
      },
      claude = {
        hide_in_model_selector = true,
      },
      copilot = {
        hide_in_model_selector = true,
      },
      gemini = {
        hide_in_model_selector = true,
      },
      vertex = {
        hide_in_model_selector = true,
      },
      vertex_claude = {
        hide_in_model_selector = true,
      },
      ["claude-haiku-3.5"] = {
        __inherited_from = "claude",
        model = "claude-3-5-haiku-20241022",
        display_name = "claude/claude-3.5-haiku",
        hide_in_model_selector = false,
      },
      ["claude-sonnet-4"] = {
        __inherited_from = "claude",
        model = "claude-sonnet-4-20250514",
        display_name = "claude/claude-sonnet-4",
        hide_in_model_selector = false,
      },
      ["copilot-claude-3.5-sonnet"] = {
        __inherited_from = "copilot",
        model = "claude-3.5-sonnet",
        display_name = "copilot/claude-3.5-sonnet",
        hide_in_model_selector = false,
      },
      ["copilot-claude-3.7-sonnet"] = {
        __inherited_from = "copilot",
        model = "claude-3.7-sonnet",
        display_name = "copilot/claude-3.7-sonnet",
        hide_in_model_selector = false,
      },
      ["copilot-claude-sonnet-4"] = {
        __inherited_from = "copilot",
        model = "claude-sonnet-4",
        display_name = "copilot/claude-sonnet-4",
        hide_in_model_selector = false,
      },
      ["copilot-gpt-4"] = {
        __inherited_from = "copilot",
        model = "gpt-4",
        display_name = "copilot/gpt-4",
        hide_in_model_selector = false,
      },
      ["copilot-gpt-4.1"] = {
        __inherited_from = "copilot",
        model = "gpt-4.1",
        display_name = "copilot/gpt-4.1",
        hide_in_model_selector = false,
      },
      ["copilot-gpt-4.1-mini"] = {
        __inherited_from = "copilot",
        model = "gpt-4.1-mini",
        display_name = "copilot/gpt-4.1-mini",
        hide_in_model_selector = false,
      },
      ["copilot-gpt-4o"] = {
        __inherited_from = "copilot",
        model = "gpt-4o",
        display_name = "copilot/gpt-4o",
        hide_in_model_selector = false,
      },
      ["copilot-gpt-4o-mini"] = {
        __inherited_from = "copilot",
        model = "gpt-4o-mini",
        display_name = "copilot/gpt-4o-mini",
        hide_in_model_selector = false,
      },
      ["copilot-o3-mini"] = {
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
      ["openai-gpt-4-1"] = {
        __inherited_from = "openai",
        model = "gpt-4.1",
        display_name = "openai/gpt-4.1",
      },
      gemini_pro = {
        __inherited_from = "gemini",
        display_name = "gemini/gemini-2.5-pro",
        model = "gemini-2.5-pro",
        hide_in_model_selector = false,
        extra_request_body = {
          temperature = 0.75,
        },
      },
      gemini_flash = {
        __inherited_from = "gemini",
        display_name = "gemini/gemini-2.5-flash",
        model = "gemini-2.5-flash",
        hide_in_model_selector = false,
        extra_request_body = {
          temperature = 0.75,
        },
      },
      gemini_flash_lite = {
        __inherited_from = "gemini",
        display_name = "gemini/gemini-2.5-flash-lite",
        model = "gemini-2.5-flash-lite-preview-06-17",
        hide_in_model_selector = false,
        extra_request_body = {
          temperature = 0.75,
        },
      },
    },
    behaviour = {
      auto_set_highlight_group = true,
      auto_apply_diff_after_generation = true,
      auto_approve_tool_permissions = true,
      enable_fastapply = false,
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
    shortcuts = {
      {
        name = "cnp",
        description = "Commit and push all staged and unstaged changes in the current repository.",
        details = "Automatically detects all modified files, summarizes the changes, generates a concise commit message, commits, and pushes to the remote repository (e.g., GitHub) in one step.",
        prompt = "Detect all staged and unstaged changes in the current git repository. Summarize the changes and generate a descriptive commit message. Commit all the changes and push them to the remote repository.",
      },
    },
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
