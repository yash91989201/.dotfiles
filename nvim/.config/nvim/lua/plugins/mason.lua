return {
  "mason-org/mason.nvim",
  opts = function(_, opts)
    vim.list_extend(opts.ensure_installed, {
      "luacheck",
      "shellcheck",
      "shfmt",
      "tailwindcss-language-server",
      "typescript-language-server",
      "css-lsp",
      "pyright",
      "json-lsp",
      "yaml-language-server",
      "dockerfile-language-server",
      "ansible-language-server",
      "terraform-lsp",
      "helm-ls",
      "sql-language-server",
      "prettier",
      "eslint_d",
      "black",
      "ruff-lsp",
    })
  end,
}
