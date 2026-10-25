return {
  "mfussenegger/nvim-lint",
  opts = {
    linters = {
      golangcilint = function()
        local linter = vim.deepcopy(require("lint.linters.golangcilint"))
        local root = vim.fs.root(vim.api.nvim_buf_get_name(0), ".golangci-version")
        if root and vim.fn.filereadable(root .. "/scripts/golangci-lint.sh") == 1 then
          -- Use the repository's pinned binary and config, including from subdirectories.
          linter.cmd = "bash"
          linter.cwd = root
          table.insert(linter.args, 2, "--config")
          table.insert(linter.args, 3, root .. "/.golangci.yml")
          table.insert(linter.args, 1, root .. "/scripts/golangci-lint.sh")
        end
        return linter
      end,
    },
  },
}
