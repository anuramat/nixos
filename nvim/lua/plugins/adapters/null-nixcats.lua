-- vim: fdl=0 fdm=marker

-- haskell formatter {{{1

-- require("conform").setup({
--   formatters_by_ft = {
--     lua = { "stylua" },
--     -- Conform will run multiple formatters sequentially
--     python = { "isort", "black" },
--     -- You can customize some of the format options for the filetype (:help conform.format)
--     rust = { "rustfmt", lsp_format = "fallback" },
--     -- Conform will run the first available formatter
--     javascript = { "prettierd", "prettier", stop_after_first = true },
--   },
-- })

local function ormolu()
  local null_ls = require('null-ls')
  local helpers = require('null-ls.helpers')
  null_ls.register({
    name = 'mdformat',
    method = null_ls.methods.FORMATTING,
    filetypes = { 'markdown' },
    generator = helpers.formatter_factory({
      to_stdin = true,
      command = 'ormolu',
      args = { '--stdin-input-file', '.' },
    }),
  })
end

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

local null_sources = function() -- {{{1
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
    f.yamlfmt,
    f.mdformat,
    ormolu,
    -- diagnostics
    -- d.statix, -- TODO turn on when they introduce pipe operator
    d.protolint,
    d.yamllint,
    -- actions
    a.statix,
    -- hovers
    h.printenv,
  }
end

-- }}}
-- alternatives:
-- - mfussenegger/nvim-lint -- linting
-- - stevearc/conform.nvim -- formatting
-- - mhartington/formatter.nvim
-- - mattn/efm-langserver -- actual LSP server, works with error messages
-- - lewis6991/hover.nvim -- hover provider
return {
  {
    'none-ls.nvim', -- maintained 'jose-elias-alvarez/null-ls.nvim' fork
    event = { 'BufReadPre', 'BufNewFile' },
    after = function()
      local null_ls = require('null-ls')
      null_ls.setup({
        sources = null_sources(),
        on_attach = require('utils.lsp').on_attach,
        temp_dir = '/tmp',
      })
    end,
  },
}