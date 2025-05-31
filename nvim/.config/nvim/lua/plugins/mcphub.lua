return {
  "ravitemer/mcphub.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  build = "npm install -g mcp-hub@latest",
  opts = {
    port = 23456,
    config = vim.fn.expand("/home/yash/.dotfiles/nvim/.config/nvim/mcp-servers.json"),
    extensions = {
      avante = {
        make_slash_commands = true,
      },
    },
  },
  keys = {
    { "<leader>ch", "<cmd>MCPHub<cr>", desc = "MCP Hub" },
  },
}
