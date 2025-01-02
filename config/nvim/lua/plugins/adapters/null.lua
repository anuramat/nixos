-- vim: fdl=0

local function latexindent()
  -- already used in texlab
  local null_ls = require('null-ls')
  local helpers = require('null-ls.helpers')
  null_ls.register({
    name = 'latexindent',
    method = null_ls.methods.FORMATTING,
    filetypes = { 'tex' },
    generator = helpers.formatter_factory({
      command = 'latexindent',
      args = { '$FILENAME' },
    }),
  })
end

-- codeblock formatter for markdown
local function cbfmt()
  -- sources are set in $XDG_CONFIG_HOME/cbfmt.toml
  local null_ls = require('null-ls')
  local helpers = require('null-ls.helpers')
  null_ls.register({
    name = 'cbfmt',
    method = null_ls.methods.FORMATTING,
    filetypes = { 'markdown' },
    generator = helpers.formatter_factory({
      to_stdin = true,
      command = 'cbfmt',
      args = { '--config', vim.fn.expand('$XDG_CONFIG_HOME') .. '/cbfmt.toml', '-p', 'markdown' },
    }),
  })
end

-- haskell formatter
local function ormolu()
  local null_ls = require('null-ls')
  local helpers = require('null-ls.helpers')
  null_ls.register({
    name = 'ormolu',
    method = null_ls.methods.FORMATTING,
    filetypes = { 'haskell' },
    generator = helpers.formatter_factory({
      to_stdin = true,
      command = 'ormolu',
      args = { '--stdin-input-file', '.' },
    }),
  })
end

local null_sources = function()
  local null_ls = require('null-ls')
  local f = null_ls.builtins.formatting
  local d = null_ls.builtins.diagnostics
  local a = null_ls.builtins.code_actions
  local h = null_ls.builtins.hover

  return {
    -- formatting
    f.stylua,
    f.black,
    f.nixfmt,
    f.markdownlint,
    cbfmt,
    ormolu,
    -- diagnostics
    -- d.statix, -- TODO turn on when they introduce pipe operator
    d.protolint,
    d.markdownlint,
    -- actions
    a.statix,
    -- hovers
    h.printenv,
  }
end

local on_attach = require('utils.lsp').on_attach

-- alternatives:
-- - mfussenegger/nvim-lint -- linting
-- - stevearc/conform.nvim -- formatting
-- - mhartington/formatter.nvim
-- - mattn/efm-langserver -- actual LSP server, works with error messages
-- - lewis6991/hover.nvim -- hover provider
return {
  'nvimtools/none-ls.nvim', -- maintained 'jose-elias-alvarez/null-ls.nvim' fork
  event = { 'BufReadPre', 'BufNewFile' },
  dependencies = 'nvim-lua/plenary.nvim',
  config = function()
    local null_ls = require('null-ls')
    null_ls.setup({
      sources = null_sources(),
      on_attach = on_attach,
      border = vim.g.border,
      temp_dir = '/tmp',
    })
  end,
}
