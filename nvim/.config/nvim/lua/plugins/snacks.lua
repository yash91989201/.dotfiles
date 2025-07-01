return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      sources = {
        explorer = {
          include = { "*.env*" },
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
