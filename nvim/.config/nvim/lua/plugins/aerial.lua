return {
  "stevearc/aerial.nvim",
  event = function()
    return {}
  end,
  cmd = { "AerialToggle", "AerialOpen", "AerialClose", "AerialNavToggle", "AerialNext", "AerialPrev" },
  lazy = true,
  opts = {
    layout = {
      max_width = 42,
      min_width = 30,
      resize_to_content = true,
    },
    lazy_load = true,
    backends = { "treesitter", "lsp", "markdown", "asciidoc", "man" },
    filter_kind = false,
    show_guides = true,
    highlight_on_hover = true,
    manage_folds = false,
    link_folds_to_tree = false,
    link_tree_to_folds = false,
    autojump = true,
  },
  keys = {
    {
      "<leader>cp",
      function()
        require("aerial").snacks_picker()
      end,
      desc = "Aerial (Symbols) Picker",
    },
  },
}
