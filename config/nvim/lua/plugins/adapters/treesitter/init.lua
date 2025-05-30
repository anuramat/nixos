-- vim: fdl=3
local textobjects = require('plugins.adapters.treesitter.textobjects')

-- TODO triple check
-- BUG E490: no fold found <https://github.com/neovim/neovim/issues/28692>
return {
  textobjects.miniai,
  -- treesitter
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    -- enabled = false,
    dependencies = {
      {
        -- TODO this fucking shit doesn't work
        'nvim-treesitter/nvim-treesitter-textobjects',
        branch = 'main',
        opts = textobjects.txtobj_cfg,
      },
      {
        'nvim-treesitter/nvim-treesitter-context',
        opts = {
          enable = true,
          max_lines = 1, -- How many lines the window should span. Values <= 0 mean no limit.
          min_window_height = 20, -- Minimum editor window height to enable context. Values <= 0 mean no limit.
          line_numbers = true,
          multiline_threshold = 1, -- Maximum number of lines to show for a single context
          trim_scope = 'outer', -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
          mode = 'cursor', -- Line used to calculate context. Choices: 'cursor', 'topline'
          -- separator = '―', -- Separator between context and content. nil or a single character
          zindex = 20, -- The Z-index of the context window
        },
      },
    },
  },
  event = { 'BufReadPre', 'BufNewFile' },
  opts = {
    highlight = {
      enable = true,
      disable = {
        -- tex conflicts with vimtex
      },
    },
    indent = {
      enable = true,
      disable = {
        'markdown', -- to make `gq` properly wrap lists
      },
    },
    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = '<c-space>',
        node_incremental = '<c-space>',
        scope_incremental = false,
        node_decremental = '<bs>',
      },
      additional_vim_regex_highlighting = {}, -- use both `:syntax` and Treesitter
    },
  },
  -- folding:
  -- vim.opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
  -- vim.opt.fdm = 'expr'
}
