return {
  "folke/snacks.nvim",
  opts = {
    scroll = { enabled = false },
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
          -- winbar is left unset: snacks gives floats "" and splits a title
          -- ("1: bash") that tells the right/bottom terminals apart.
          number = true,
          relativenumber = true,
        },
      },
    },
  },
}
