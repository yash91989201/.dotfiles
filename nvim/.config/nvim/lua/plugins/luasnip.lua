return {
  "L3MON4D3/LuaSnip",
  event = "InsertEnter",
  dependencies = {
    "rafamadriz/friendly-snippets",
  },
  build = "make install_jsregexp", -- optional but helps some snippet features
  config = function()
    require("luasnip.loaders.from_vscode").lazy_load()
  end,
}
