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
      ["gemini-pro"] = {
        __inherited_from = "gemini",
        display_name = "gemini/gemini-2.5-pro",
        model = "gemini-2.5-pro",
        hide_in_model_selector = false,
      },
      ["gemini-flash"] = {
        __inherited_from = "gemini",
        display_name = "gemini/gemini-2.5-flash",
        model = "gemini-2.5-flash",
        hide_in_model_selector = false,
      },
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
        description = "Commit and push all staged and unstaged changes in the current Git repository with a clear, point-wise, intent-based commit message.",
        details = "Detects all file changes, interprets their purpose, generates a commit message that is concise yet descriptive (point-wise if needed), then commits and pushes.",
        prompt = [[
Detect all staged and unstaged changes in the current Git repository.

1. **Analyze changes** to determine the purpose, feature, or fix.
2. **Focus on intent** — what and why, not raw file stats.
3. **Write a commit message** that is:
   - Concise yet descriptive.
   - Bullet points for multiple related changes.
   - Imperative mood (e.g., "Enable dark mode").
   - Understandable to humans, minimal low-level details.
4. For unrelated intents, create separate commits.
5. Commit all changes and push to remote.

Example: 
If a config change enables dark mode support and improves accessibility in the UI.

✅ Correct:  
Improve UI accessibility and enable dark mode -  
1. Enabled dark mode in settings.  
2. Increased text contrast.  
3. Added keyboard navigation.

❌ Incorrect:  
`Changed config option from false to true for dark_mode`  
`Updated 3 files in UI module`
]],
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
        name = "implement",
        description = "Plan and implement a feature using Shrimp Task Manager MCP, with optional use of context7 and grep mcp.",
        details = "Guides AI through Shrimp’s structured workflow for planning, executing, and verifying a feature, while allowing use of context7 for latest docs and grep for code patterns/examples.",
        prompt = [[
Use Shrimp Task Manager MCP to plan and implement the requested feature.

1. Analyze and clarify the request.
2. If needed, enter research mode (Shrimp Task Manager MCP) to explore solutions and best practices.
3. For latest documentation on tools/packages, use context7 MCP.
4. For real-world code examples or patterns from repos, use grep MCP.
5. Break the feature into subtasks, define dependencies, priorities, and assess complexity.
6. Check Task Memory to reuse relevant past work.
7. Provide step-by-step instructions for each subtask with any required code/config changes.
8. Execute in order, track progress, verify results, and summarize completion.

Below is user’s request:
]],
      },
      {
        name = "og",
        description = "Operational Guidelines",
        details = "Clear, enforceable operational rules to ensure tasks are completed efficiently, accurately, and with minimal unnecessary actions or file reads.",
        prompt = [[
Operational Guidelines (Strict Adherence Required):

1. **Tool Usage** — Use MCP tools *only* when they are essential for efficiently completing the current task. Avoid unnecessary tool calls.
2. **File Editing** — Make minimal, targeted changes when editing file that *directly* fulfill the stated requirement. Avoid formatting changes, refactoring, or style edits unless explicitly requested.
3. **Task Scope** — Stay strictly within the boundaries of the current task. Do not attempt to add enhancements, refactor unrelated areas, or address issues not mentioned.
4. **File Access** — Only read files absolutely necessary to complete the current task. Avoid scanning the entire codebase unless it is unavoidable.
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
