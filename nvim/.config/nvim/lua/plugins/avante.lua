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
    "takeshiD/avante-status.nvim",
    {
      "MeanderingProgrammer/render-markdown.nvim",
      opts = {
        file_types = { "markdown", "Avante" },
      },
      ft = { "markdown", "Avante" },
    },
  },
  opts = {
    provider = "copilot-gpt-5-mini",
    providers = {
      ["copilot-gpt-5-mini"] = {
        __inherited_from = "copilot",
        model = "gpt-5-mini",
        display_name = "GPT 5 Mini (x0) (Default)",
        hide_in_model_selector = false,
      },
      ["copilot-gpt-4.1"] = {
        __inherited_from = "copilot",
        model = "gpt-4.1",
        display_name = "GPT 4.1 (x0)",
        hide_in_model_selector = false,
      },
      ["copilot-gpt-4o"] = {
        __inherited_from = "copilot",
        model = "gpt-4o",
        display_name = "GPT 4o (x0)",
        hide_in_model_selector = false,
      },
      ["copilot-gpt-5"] = {
        __inherited_from = "copilot",
        model = "gpt-5",
        display_name = "GPT 5 (x1)",
        hide_in_model_selector = false,
      },
      ["copilot-gpt-o3"] = {
        __inherited_from = "copilot",
        model = "gpt-o3",
        display_name = "GPT o3 (x1)",
        hide_in_model_selector = false,
      },
      ["copilot-gpt-o4-mini"] = {
        __inherited_from = "copilot",
        model = "gpt-o4-mini",
        display_name = "GPT o4 Mini (x0.33)",
        hide_in_model_selector = false,
      },
      ["copilot-claude-opus-41"] = {
        __inherited_from = "copilot",
        model = "claude-opus-41",
        display_name = "Claude Opus 4.1 (x10)",
        hide_in_model_selector = false,
      },
      ["copilot-claude-sonnet-4"] = {
        __inherited_from = "copilot",
        model = "claude-sonnet-4",
        display_name = "Claude Sonnet 4 (x1)",
        hide_in_model_selector = false,
      },
      ["copilot-claude-3.7-sonnet-thought"] = {
        __inherited_from = "copilot",
        model = "claude-3.7-sonnet-thought",
        display_name = "Claude Sonnet 3.7 Thinking (x1.25)",
        hide_in_model_selector = false,
      },
      ["copilot-claude-3.7-sonnet"] = {
        __inherited_from = "copilot",
        model = "claude-3.7-sonnet",
        display_name = "Claude Sonnet 3.7 (x1)",
        hide_in_model_selector = false,
      },
      ["copilot-claude-3.5-sonnet"] = {
        __inherited_from = "copilot",
        model = "claude-3.5-sonnet",
        display_name = "Claude Sonnet 3.5 (x1)",
        hide_in_model_selector = false,
      },
      ["copilot-grok-code-fast-1"] = {
        __inherited_from = "copilot",
        model = "grok-code-fast-1",
        display_name = "Grok Code Fast 1 (x0.25)",
        hide_in_model_selector = false,
      },
      ["copilot-gemini-2.5-pro"] = {
        __inherited_from = "copilot",
        model = "gemini-2.5-pro",
        display_name = "Gemini 2.5 Pro (x1)",
        hide_in_model_selector = false,
      },
      ["copilot-gemini-2.0-flash"] = {
        __inherited_from = "copilot",
        model = "gemini-2.0-flash",
        display_name = "Gemini 2.0 Flash (x0.25)",
        hide_in_model_selector = false,
      },
      copilot = { hide_in_model_selector = true },
      gemini = { hide_in_model_selector = true },
      claude = { hide_in_model_selector = true },
      vertex = { hide_in_model_selector = true },
      vertex_claude = { hide_in_model_selector = true },
      openai = { hide_in_model_selector = true },
      morph = { hide_in_model_selector = true },
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
        description = "Stage, commit, and push all changes with intent-focused, logical commit separation.",
        details = "Analyze changes by purpose, create separate commits per intent, use conventional format with bullet points.",
        prompt = [[
You are a Git assistant. Use `git` MCP tools to execute this workflow (enable MCPHub if required).

### Step 1: Review Changes
  - Use `git_status` to list modified, staged, and untracked files.
  - Use `git_diff_unstaged` to inspect working directory changes.
  - Use `git_diff_staged` to inspect staged changes.
  - Exclude temp, build, and sensitive files from staging.

### Step 2: Smart Staging by Intent
  - Group related changes logically (feature, bugfix, refactor, docs, style, config).
  - Stage files for each group with `git_add`.
  - If needed, reset with `git_reset` before regrouping.

### Step 3: Commit by Intent
  - For each group of staged changes, use `git_commit` with a **Conventional Commit** style message:
    - Format: `type(scope): description`
      - **Types:** feat, fix, docs, style, refactor, test, chore, perf
      - Use imperative mood (e.g., "Add", "Fix", "Update")
      - Keep subject line ≤ 50 chars
    - Body (optional, use bullet points):
      - What changed (specific components)
      - Why changed (reason, user/business benefit)

### Step 4: Push
  - Push all commits to the current branch’s remote using bash tool.

### Rules
  - NO generic commit messages (avoid "update files", "fix issues").
  - Never mix unrelated changes in one commit.
  - Be descriptive, precise, and action-oriented.
  - Always use MCP tool syntax correctly (`git_add`, `git_commit`, etc.).
  - Execute workflow **without asking for confirmation**.
  - Stay strictly within the boundaries of the current workflow.
  - Do not output unnecessary information; only show failure messages if an operation fails.

### Examples

feat(auth): implement OAuth2 integration
  - add Google OAuth provider config
  - create user session management

fix(ui): resolve mobile navigation accessibility
  - increase touch target sizes to 44px minimum
  - add ARIA labels and keyboard focus trap
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
