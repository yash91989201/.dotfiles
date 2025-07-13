return {
  "ravitemer/mcphub.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
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
