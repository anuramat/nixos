-- vim: fdl=3
return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'master',
    -- enabled = false,
    dependencies = {
      'nvim-treesitter/nvim-treesitter-textobjects',
      'nvim-treesitter/nvim-treesitter-context',
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
      ensure_installed = false, -- install missing parsers on launch
      auto_install = true, -- install corresponding parser on buffer enter
      ignore_install = {},
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
      textobjects = {
        swap = {
          enable = true,
          swap_next = {
            ['<a-l>'] = {
              query = { '@parameter.inner' },
              desc = 'swap with the next parameter',
            },
            ['<a-j>'] = {
              query = { '@code_block.outer' },
              desc = 'swap with the cell below',
            },
          },
          swap_previous = {
            ['<a-h>'] = {
              query = { '@parameter.inner' },
              desc = 'swap with the previous parameter',
            },
            ['<a-k>'] = {
              query = { '@code_block.outer' },
              desc = 'swap with the cell above',
            },
          },
        },
      },
    },
    config = function(_, opts)
      require('nvim-treesitter.configs').setup(opts)
      require('treesitter-context').setup({
        enable = true,
        max_lines = 1, -- How many lines the window should span. Values <= 0 mean no limit.
        min_window_height = 20, -- Minimum editor window height to enable context. Values <= 0 mean no limit.
        line_numbers = true,
        multiline_threshold = 1, -- Maximum number of lines to show for a single context
        trim_scope = 'outer', -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
        mode = 'cursor', -- Line used to calculate context. Choices: 'cursor', 'topline'
        -- separator = '―', -- Separator between context and content. nil or a single character
        zindex = 20, -- The Z-index of the context window
      })
      vim.opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
      vim.opt.fdm = 'expr'
    end,
  },
  {
    'windwp/nvim-ts-autotag',
    ft = { 'html', 'xml', 'jsx', 'javascript' }, -- more are available
    opts = {},
  },
}
