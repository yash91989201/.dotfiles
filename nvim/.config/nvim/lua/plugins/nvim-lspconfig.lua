return {
  "neovim/nvim-lspconfig",
  opts = function(_, opts)
    opts.inlay_hints = {
      enabled = false,
      exclude = { "vue" },
    }

    opts.servers = opts.servers or {}
    -- Official templ LSP (`templ lsp`); see https://templ.guide/developer-tools/cli/
    -- and LazyVim discussion #3735 for the community LazyVim wiring.
    opts.servers.templ = {
      filetypes = { "templ" },
      settings = {
        templ = {
          enable_snippets = true,
        },
      },
    }

    -- Treat .templ like HTML for markup-oriented language servers.
    opts.servers.html = vim.tbl_deep_extend("force", opts.servers.html or {}, {
      filetypes = { "html", "templ" },
    })

    opts.servers.emmet_language_server = opts.servers.emmet_language_server or {}
    opts.servers.tailwindcss = opts.servers.tailwindcss or {}
    opts.servers.tailwindcss.settings = vim.tbl_deep_extend("force", opts.servers.tailwindcss.settings or {}, {
      tailwindCSS = {
        lint = {
          suggestCanonicalClasses = true,
        },
        includeLanguages = {
          templ = "html",
        },
      },
    })

    opts.setup = opts.setup or {}

    -- Extend server filetypes with templ without dropping lspconfig/LazyVim defaults.
    local function with_templ_filetype(server, server_opts)
      local fts = server_opts.filetypes
      if not fts then
        local cfg = vim.lsp.config[server]
        fts = (cfg and cfg.filetypes) or {}
      end
      server_opts.filetypes = vim.deepcopy(fts)
      if not vim.tbl_contains(server_opts.filetypes, "templ") then
        table.insert(server_opts.filetypes, "templ")
      end
    end

    local prev_tw = opts.setup.tailwindcss
    opts.setup.tailwindcss = function(server, server_opts)
      with_templ_filetype(server, server_opts)
      if type(prev_tw) == "function" then
        return prev_tw(server, server_opts)
      end
    end

    local prev_emmet = opts.setup.emmet_language_server
    opts.setup.emmet_language_server = function(server, server_opts)
      with_templ_filetype(server, server_opts)
      if type(prev_emmet) == "function" then
        return prev_emmet(server, server_opts)
      end
    end
  end,
}
