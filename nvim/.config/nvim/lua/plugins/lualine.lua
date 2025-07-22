return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    local mcphub_lualine_config = {
      function()
        if not vim.g.loaded_mcphub then
          return "󰐻 ⚠"
        end

        local count = vim.g.mcphub_servers_count or 0
        local status = vim.g.mcphub_status or "stopped"
        local executing = vim.g.mcphub_executing

        if status == "stopped" then
          return "󰐻 ⊗"
        end

        -- Show spinner when executing, starting, or restarting
        if executing or status == "starting" or status == "restarting" then
          local frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
          local frame = math.floor(vim.uv.hrtime() / 1e6 / 100) % #frames + 1
          return "󰐻 " .. frames[frame]
        end

        return "󰐻 " .. count
      end,
      color = function()
        if not vim.g.loaded_mcphub then
          return { fg = "#737aa2" }
        end

        local status = vim.g.mcphub_status or "stopped"
        if status == "ready" or status == "restarted" then
          return { fg = "#9ece6a" }
        elseif status == "starting" or status == "restarting" then
          return { fg = "#e0af68" }
        else
          return { fg = "#f7768e" }
        end
      end,
    }

    table.insert(opts.sections.lualine_x, 1, mcphub_lualine_config)
  end,
}
