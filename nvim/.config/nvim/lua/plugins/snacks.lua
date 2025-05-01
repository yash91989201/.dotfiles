return {
  {
    "folke/snacks.nvim",
    ---@type snacks.Config
    opts = {
      picker = {
        sources = {
          explorer = {
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
    },
  },
}
