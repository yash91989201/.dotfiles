return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      go = { "gofmt" },
      templ = { "templ" },
    },
    formatters = {
      templ = { command = "go", prepend_args = { "tool", "templ" } },
    },
  },
}
