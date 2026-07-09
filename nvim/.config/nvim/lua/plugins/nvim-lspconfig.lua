return {
  "neovim/nvim-lspconfig",
  opts = {
    inlay_hints = {
      enabled = false,
      exclude = { "vue" },
    },
    servers = {
      bacon_ls = {
        enabled = true,
      },
      rust_analyzer = { enabled = false },
      tailwindcss = {
        settings = {
          tailwindCSS = {
            lint = {
              suggestCanonicalClasses = true,
            },
          },
        },
      },
    },
  },
}
