return {
  "razak17/tailwind-fold.nvim",
  -- Repeated BufEnter events accumulate full-buffer TextChanged callbacks.
  enabled = false,
  event = { "BufReadPre", "BufNewFile" },
  opts = {},
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  ft = { "html", "svelte", "astro", "typescriptreact", "templ" },
}
