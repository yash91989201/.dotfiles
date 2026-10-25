return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      sources = {
        files = {
          exclude = { "*_templ.go" },
        },
        explorer = {
          include = { "*.env*" },
          exclude = { "*_templ.go" },
          win = {
            list = {
              wo = {
                number = true,
                relativenumber = true,
              },
            },
          },
        },
      },
    },
    terminal = {
      win = {
        position = "float",
        wo = {
          winbar = "",
          number = true,
          relativenumber = true,
        },
      },
    },
  },
}
