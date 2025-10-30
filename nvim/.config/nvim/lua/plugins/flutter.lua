return {
  {
    "akinsho/flutter-tools.nvim",
    ft = "dart",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    opts = {
      lsp = {
        color = {
          enabled = false,
        },
        on_attach = function(client, bufnr)
          -- Disable document formatting
          client.server_capabilities.documentFormattingProvider = false
          client.server_capabilities.documentRangeFormattingProvider = false

          -- Throttle didChange notifications
          client.config.flags = client.config.flags or {}
          client.config.flags.debounce_text_changes = 1000 -- 1 second delay
        end,
        settings = {
          dart = {
            -- Critical: Disable all auto-analysis
            analysisExcludedFolders = {
              vim.fn.expand("$HOME/.pub-cache"),
              vim.fn.expand("$HOME/fvm"),
              vim.fn.expand("$HOME/flutter"),
              vim.fn.expand("$HOME/Android"),
              vim.fn.expand("$HOME/Library"),
            },
            completeFunctionCalls = false,
            showTodos = false,
            updateImportsOnRename = false,
            enableSdkFormatter = false,
            -- Disable resource-intensive features
            enableSnippets = false,
            renameFilesWithClasses = "never",
            -- Reduce analysis scope
            includeDependenciesInWorkspaceSymbols = false,
            allowAnalytics = false,
            enableServerResponseTimes = false,
            notifyAnalyzerErrors = false,
          },
        },
        -- Only start in actual Flutter projects
        root_dir = function(fname)
          local util = require("lspconfig.util")
          return util.root_pattern("pubspec.yaml")(fname)
        end,
        capabilities = (function()
          local capabilities = vim.lsp.protocol.make_client_capabilities()
          -- Disable some capabilities to reduce load
          capabilities.textDocument.completion.completionItem.snippetSupport = false
          capabilities.textDocument.colorProvider = { dynamicRegistration = false }
          return capabilities
        end)(),
      },
      -- Disable everything else
      debugger = { enabled = false },
      widget_guides = { enabled = false },
      closing_tags = { enabled = false },
      dev_log = { enabled = false },
      outline = { auto_open = false },
    },
  },
}
