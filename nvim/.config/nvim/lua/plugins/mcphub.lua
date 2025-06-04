return {
  "ravitemer/mcphub.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  build = "npm install -g mcp-hub@latest",
  opts = {
    port = 32658,
    config = vim.fn.expand("~/.config/nvim/mcp/servers.json"),
  },
  keys = {
    { "<leader>cH", "<cmd>MCPHub<cr>", desc = "MCP Hub" },
  },
}
