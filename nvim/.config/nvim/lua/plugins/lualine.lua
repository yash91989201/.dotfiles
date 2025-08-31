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

    local avante_model_config = {
      function()
        -- Try to get the current configuration
        local avante_config_ok, avante_config = pcall(require, "avante.config")
        if avante_config_ok and avante_config then
          -- Get the current provider
          local current_provider = avante_config.provider
          if not current_provider then
            return nil
          end

          -- Get the provider configuration
          local provider_config = avante_config.providers and avante_config.providers[current_provider]
          if provider_config then
            -- Return the display_name if available, otherwise fallback to model name
            if provider_config.display_name then
              return "🤖 " .. provider_config.display_name
            elseif provider_config.model then
              return "🤖 " .. provider_config.model
            end
          end

          -- Fallback to provider name
          return "🤖 " .. current_provider
        end

        -- Alternative method: try to access config directly
        local config_ok, config = pcall(require, "avante")
        if config_ok and config.Config then
          local current_provider = config.Config.provider
          if current_provider then
            local provider_config = config.Config.providers and config.Config.providers[current_provider]
            if provider_config and provider_config.display_name then
              return "🤖 " .. provider_config.display_name
            end
            return "🤖 " .. current_provider
          end
        end

        return nil
      end,
      color = { fg = "#bb9af7" }, -- Purple color, customize as needed
      cond = function()
        -- Only show if we can get config info
        local avante_config_ok, avante_config = pcall(require, "avante.config")
        if avante_config_ok and avante_config and avante_config.provider then
          return true
        end
        local config_ok, config = pcall(require, "avante")
        return config_ok and config.Config and config.Config.provider
      end,
    }

    -- Insert both configurations into lualine_x
    table.insert(opts.sections.lualine_x, 1, mcphub_lualine_config)
    table.insert(opts.sections.lualine_x, 2, avante_model_config)
  end,
}
