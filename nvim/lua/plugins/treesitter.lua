local specs = {}
local k = require('config.keys')
local u = require('utils')

local langs = {
  'go', 'gosum', 'gomod', 'gowork', 'python', 'haskell', 'bash', 'c', 'json',
  'lua', 'luadoc', 'luap', 'markdown', 'markdown_inline', 'python', 'query',
  'regex', 'vim', 'vimdoc', 'yaml', 'sql'
}

specs.treesitter = {
  'nvim-treesitter/nvim-treesitter',
  version = false, -- last release is way too old
  build = ':TSUpdate',
  event = { 'VeryLazy', 'BufReadPre', 'BufNewFile' },
  dependencies = {
    'nvim-treesitter/nvim-treesitter-textobjects',
    'JoosepAlviste/nvim-ts-context-commentstring',
  },
  opts = {
    highlight = { enable = true },
    indent = { enable = true }, -- noexpandtab is broken with python
    ensure_installed = langs,
    incremental_selection = {
      enable = true,
      keymaps = k.treesitter.inc_selection,
    },
    textobjects = {
      swap = u.merge({ enable = true }, k.treesitter.textobj_swap)
    },
    context_commentstring = {
      enable = true,
      enable_autocmd = false, -- Comment.nvim takes care of this
    },
  },
  config = function(_, opts)
    require('nvim-treesitter.configs').setup(opts)
    -- vim.opt.foldmethod = 'expr'
    -- vim.opt.foldexpr = 'nvim_treesitter#foldexpr()'
    require('ufo').setup({
      provider_selector = function(bufnr, filetype, buftype)
        return { 'treesitter', 'indent' }
      end
    })
  end,
}
return u.values(specs)
