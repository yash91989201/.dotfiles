return {
  "ravitemer/mcphub.nvim",
  event = "VeryLazy",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
  },
  build = "npm install -g mcp-hub@latest",
  opts = {
    config = vim.fn.expand("~/.config/nvim/mcp/servers.json"),
    auto_approve = true,
  },
  keys = {
    { "<leader>ch", "<cmd>MCPHub<cr>", desc = "MCP Hub" },
  },
}
