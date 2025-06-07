-- LSP configuration for nixcats + lze
local ul = require('utils.lsp')

local optionsExpr = string.format('(builtins.getFlake "/etc/nixos/").nixosConfigurations.%s.options', vim.fn.hostname())
local homeExpr = optionsExpr .. '.home-manager.users.type.getSubOptions []'

local configs = function()
  return {
    nixd = {
      cmd = { 'nixd', '--inlay-hints=false' },
      settings = {
        nixd = {
          options = {
            nixos = { expr = optionsExpr },
            ['home-manager'] = { expr = homeExpr },
          },
          diagnostic = {
            suppress = {},
          },
        },
      },
    },
    nil_ls = {},
    yamlls = {},
    superhtml = {},
    ts_ls = {},
    stylelint_lsp = {
      settings = {
        stylelintplus = {},
      },
    },
    jsonls = {
      cmd = { 'vscode-json-languageserver', '--stdio' },
      schemas = require('schemastore').json.schemas(),
    },
    texlab = {
      settings = {
        texlab = {
          build = {
            forwardSearchAfter = true,
            onSave = true,
          },
          chktex = {
            onEdit = true,
            onOpenAndSave = true,
          },
          forwardSearch = {
            executable = 'zathura',
            args = { '--synctex-forward', '%l:1:%f', '%p' },
          },
        },
      },
    },
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
        ul.on_attach(client, buffer)
        require('clangd_extensions.inlay_hints').setup_autocmd()
        require('clangd_extensions.inlay_hints').set_inlay_hints()
      end,
      filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda' },
    },
    gopls = {
      settings = {
        gopls = {
          analyses = {
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
            compositeLiteralFields = false,
            compositeLiteralTypes = false,
            constantValues = false,
            functionTypeParameters = false,
            parameterNames = false,
            rangeVariableTypes = false,
          },
          usePlaceholders = true,
          staticcheck = true,
          gofumpt = true,
          semanticTokens = true,
        },
      },
      root_dir = ul.root_dir_with_fallback({
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
          format = {
            enable = false,
          },
          telemetry = {
            enable = false,
          },
        },
      },
    },
  }
end

return {
  "nvim-lspconfig",
  event = { "BufReadPost", "BufNewFile" },
  after = function()
    local lspconfig = require('lspconfig')
    for name, cfg in pairs(configs()) do
      vim.lsp.config(name, {
        capabilities = require('blink.cmp').get_lsp_capabilities(),
      })
      cfg.on_attach = cfg.on_attach or ul.on_attach
      lspconfig[name].setup(cfg)
    end
  end,
}