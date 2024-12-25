-- vim: fdl=2

local on_attach = require('utils.lsp').on_attach

--- Root directory function with a fallback
--- @param opts { primary: string[], fallback: string[] }
local root_dir_with_fallback = function(opts)
  local util = require('lspconfig.util')
  return function(fname)
    local primary_root = util.root_pattern(unpack(opts.primary))(fname)
    local fallback_root = util.root_pattern(unpack(opts.fallback))(fname)
    return primary_root or fallback_root
  end
end

-- <https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md>
--- Returns configs for specific lsps
--- @return table configs
local configs = function()
  return {
    -- supports options, packages
    nixd = {
      cmd = { 'nixd', '--inlay-hints=false' },
      settings = {
        nixd = {
          diagnostic = {
            suppress = {
              'sema-escaping-with',
              'escaping-this-with',
              'sema-extra-with',
            },
          },
        },
      },
    },
    -- nil_ls = {}, -- nice code actions
    yamlls = {
      -- we can use schemastore plugin if we need more logic
      -- eg replacements or custom schemas
    },
    jsonls = {
      cmd = { 'vscode-json-languageserver', '--stdio' },
      schemas = require('schemastore').json.schemas(),
    },
    texlab = {},
    bashls = {
      settings = {
        bashIde = {
          shfmt = {
            binaryNextLine = true,
            caseIndent = true,
            simplifyCode = true,
            spaceRedirects = true,
          },
        },
      },
    },
    pyright = {
      settings = {
        python = {},
      },
    },
    marksman = {},
    clangd = {
      on_attach = function(client, buffer)
        vim.api.nvim_buf_set_keymap(
          buffer,
          'n',
          '<localleader>6',
          '<cmd>ClangdSwitchSourceHeader<cr>',
          { silent = true, desc = 'clangd: Switch between .c/.h' }
        )
        on_attach(client, buffer)
        require('clangd_extensions.inlay_hints').setup_autocmd()
        require('clangd_extensions.inlay_hints').set_inlay_hints()
      end,
      filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda' }, -- 'proto' removed
    },
    gopls = {
      settings = {
        gopls = {
          analyses = {
            fieldalignment = true,
            shadow = true,
            unusedwrite = true,
            useany = true,
            unusedvariable = true,
          },
          codelenses = {
            gc_details = true,
            generate = true,
            regenerate_cgo = true,
            tidy = true,
            upgrade_dependency = true,
            vendor = true,
          },
          hints = {
            assignVariableTypes = false,
            compositeLiteralFields = true,
            compositeLiteralTypes = true,
            constantValues = true,
            functionTypeParameters = true,
            parameterNames = false,
            rangeVariableTypes = true,
          },
          usePlaceholders = true,
          staticcheck = true,
          gofumpt = true,
          semanticTokens = true,
        },
      },
      root_dir = root_dir_with_fallback({
        primary = { '.git' },
        fallback = { 'go.work', 'go.mod' },
      }),
    },
    lua_ls = {
      settings = {
        Lua = {
          runtime = {
            version = 'LuaJIT',
          },
          -- workspace = {
          --   checkThirdParty = 'Disable', -- already in .luarc.json
          -- },
          format = {
            enable = false, -- using stylua instead
          },
          -- hint = {
          --   enable = true, -- kinda annoying
          -- },
          telemetry = {
            enable = false,
          },
        },
      },
    },
  }
end

return {
  'neovim/nvim-lspconfig',
  event = { 'BufReadPre', 'BufNewFile' },
  dependencies = {
    'hrsh7th/nvim-cmp',
    'ray-x/lsp_signature.nvim',
    'b0o/schemastore.nvim',
  },
  config = function()
    local lspconfig = require('lspconfig')
    -- ~~~~~~~~~~~~~~~~ Borders styling ~~~~~~~~~~~~~~~~~ --
    -- add border to `:LspInfo` menu
    require('lspconfig.ui.windows').default_options.border = vim.g.border
    -- -- add border to default hover handler
    vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(vim.lsp.handlers.hover, { border = vim.g.border })
    -- -- add border to default signature help (replaced with ray-x/lsp_signature.nvim)
    -- vim.lsp.handlers['textDocument/signatureHelp'] =
    --   vim.lsp.with(vim.lsp.handlers.signature_help, { border = vim.g.border })
    -- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ --
    -- Register capabilities for CMP
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)
    -- ~~~~~~~~~~~~~~~~ Set up servers ~~~~~~~~~~~~~~~~~ --
    for name, cfg in pairs(configs()) do
      cfg.capabilities = capabilities
      if cfg.on_attach == nil then
        cfg.on_attach = on_attach
      end
      lspconfig[name].setup(cfg)
    end

    require('lsp_signature').setup({
      handler_opts = { border = vim.g.border },
      always_trigger = true,
      hint_enable = false, -- virtual hint enable
      hint_prefix = '🐼 ', -- Panda for parameter (hehe)
    })
  end,
}
