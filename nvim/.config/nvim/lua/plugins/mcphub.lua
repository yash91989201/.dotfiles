return {
  "ravitemer/mcphub.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  build = "npm install -g mcp-hub@latest",
  opts = {
    port = 23456,
    config = "/home/yash/.config/nvim/mcp-servers.json",
  },
  keys = {
    { "<leader>cM", "<cmd>MCPHub<cr>", desc = "MCP Hub" },
  },
}
