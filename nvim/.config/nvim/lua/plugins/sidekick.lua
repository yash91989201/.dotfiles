return {
  "folke/sidekick.nvim",
  opts = {
    -- NES needs the Copilot LSP; this setup only uses the claude/codex CLIs
    nes = { enabled = false },
    copilot = { status = { enabled = false } },
  },
  config = function(_, opts)
    require("sidekick").setup(opts)
    -- setup() deep-merges defaults, so drop unused providers after it runs
    local tools = require("sidekick.config").cli.tools
    for name in pairs(tools) do
      if name ~= "claude" and name ~= "codex" then
        tools[name] = nil
      end
    end
  end,
  keys = {
    {
      "<leader>aa",
      function()
        require("sidekick.cli").toggle({ name = "claude", focus = true })
      end,
      desc = "Sidekick Toggle Claude",
    },
  },
}
