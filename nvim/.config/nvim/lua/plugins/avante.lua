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
      openai = {
        hide_in_model_selector = true,
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
      ["copilot-gpt-4.1"] = {
        __inherited_from = "copilot",
        model = "gpt-4.1",
        display_name = "copilot/gpt-4.1",
        hide_in_model_selector = false,
      },
      ["copilot-gpt-4o"] = {
        __inherited_from = "copilot",
        model = "gpt-4o",
        display_name = "copilot/gpt-4o",
        hide_in_model_selector = false,
      },
      ["gemini-pro"] = {
        __inherited_from = "gemini",
        display_name = "gemini/gemini-2.5-pro",
        model = "gemini-2.5-pro",
        hide_in_model_selector = false,
        extra_request_body = {
          temperature = 0.7,
        },
      },
      ["gemini-flash"] = {
        __inherited_from = "gemini",
        display_name = "gemini/gemini-2.5-flash",
        model = "gemini-2.5-flash",
        hide_in_model_selector = false,
        extra_request_body = {
          temperature = 0.7,
        },
      },
    },
    behaviour = {
      auto_set_highlight_group = true,
      auto_apply_diff_after_generation = true,
      auto_approve_tool_permissions = true,
      enable_fastapply = true,
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
    rag_service = {
      enabled = false,
      host_mount = vim.fn.getcwd(),
    },
    shortcuts = {
      {
        name = "cnp",
        description = "Commit and push all staged and unstaged changes in the current Git repository.",
        details = "Detects all file changes, summarizes them, generates a meaningful commit message, commits, and pushes to the remote repository in one step.",
        prompt = "Detect all staged and unstaged changes in the current Git repository. Summarize the changes and generate a concise, descriptive commit message. Then commit and push all changes to the remote repository.",
      },
      {
        name = "dtcp",
        description = "Delegate a coding task to the GitHub Copilot agent.",
        details = "This command uses the GitHub MCP server to create an issue from the user's request and assign it to the Copilot agent.",
        prompt = [[
Use the GitHub MCP tools to delegate the task:

1. Use `create_issue` to open a new GitHub issue.
   - Title: A short summary of the user's task
   - Body: A clear, detailed version of the user's request

2. Use `assign_copilot_to_issue` to assign the Copilot agent to the issue.

Here is the task to delegate:
]],
      },
      {
        name = "dtcc",
        description = "Delegate a coding task to Claude Code.",
        details = "This command interprets the user's request and generates a structured prompt to ensure accurate task execution.",
        prompt = [[
Your task is to *delegate* the user's request to Claude Code MCP — not to solve it yourself.

Follow the Claude Code MCP instructions to create a clear, properly formatted command for Claude Code MCP to execute.

Structure your output as a complete, ready-to-submit prompt, and then invoke the Claude Code MCP to perform the task.

Here is the user's request:
]],
      },
    },
    windows = {
      width = 38,
      input = {
        height = 12,
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
