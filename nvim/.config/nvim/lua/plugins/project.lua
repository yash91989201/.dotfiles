return {
  {
    "ahmedkhalf/project.nvim",
    opts = {
      manual_mode = false,
      detection_methods = { "pattern" },
      patterns = { ".git" },
      silent_chdir = true,
      scope_chdir = "global",
    },
  },
}
