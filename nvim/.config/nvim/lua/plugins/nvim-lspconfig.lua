return {
  "neovim/nvim-lspconfig",
  servers = {
    denols = {
      root_dir = require("lspconfig").util.root_pattern({ "deno.json", "deno.jsonc" }),
      single_file_support = false,
      settings = {},
    },
  },
  opts = {
    inlay_hints = {
      enabled = false,
    },
  },
}
