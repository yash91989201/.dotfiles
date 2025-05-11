return {
  "stevearc/aerial.nvim",
  event = "LspAttach",
  opts = {
    layout = {
      max_width = 50,
      min_width = 35,
      resize_to_content = true,
    },
    lazy_load = true,
    backends = { "treesitter", "lsp", "markdown", "asciidoc", "man" },
    filter_kind = false,
    show_guides = true,
    highlight_on_hover = true,
    manage_folds = true,
    link_folds_to_tree = true,
    link_tree_to_folds = true,
    autojump = true,
  },
}
