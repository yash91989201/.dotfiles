return {
  "yetone/avante.nvim",
  -- Commands and keymaps from the Avante extra load it on demand.
  event = function()
    return {}
  end,
  lazy = true,
  version = false,
  build = "make",
  dependencies = {
    { "ColinKennedy/mega.cmdparse", dependencies = { "ColinKennedy/mega.logging" } },
  },
  config = function(_, opts)
    require("avante").setup(opts)
    local Sidebar = require("avante.sidebar")
    local Helpers = require("avante.history.helpers")
    local get_message_lines = Sidebar.get_message_lines
    -- Hide routine tool activity only in the sidebar; keep it in model history.
    Sidebar.get_message_lines = function(self, ctx, message, messages, ignore_record_prefix)
      local tool = Helpers.get_tool_use_data(message)
      if tool and tool.name ~= "attempt_completion" and not self.permission_handler then
        local result = Helpers.get_tool_result(tool.id, messages)
        if not result or not result.is_error then
          return {}
        end
      end
      return get_message_lines(self, ctx, message, messages, ignore_record_prefix)
    end
  end,
  opts = {
    provider = "ds-v4.1-flash",
    system_prompt = [[
Present the final answer exactly once, only in the attempt_completion tool's result.
Do not output the answer as ordinary assistant text before or after calling attempt_completion.
For explanations and questions that need no tools, call attempt_completion directly with the answer.
Keep answers concise and do not output thinking, planning, or commentary about tool usage.
]],
    providers = {
      ["ds-v4.1-flash"] = {
        __inherited_from = "openai",
        endpoint = "https://opencode.ai/zen/go/v1",
        model = "deepseek-v4.1-flash",
        api_key_name = "OPENCODE_GO_API_KEY",
        parse_curl_args = require("config.avante-go").parse_curl_args,
        extra_request_body = {
          thinking = { type = "disabled" },
        },
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
    windows = {
      width = 36,
      input = {
        height = 14,
      },
    },
  },
}
