-- vim: fdl=3
return {
  -- treesitter
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
              query = { '@block.outer' },
              desc = 'swap with the block below',
            },
          },
          swap_previous = {
            ['<a-h>'] = {
              query = { '@parameter.inner' },
              desc = 'swap with the previous parameter',
            },
            ['<a-k>'] = {
              query = { '@block.outer' },
              desc = 'swap with the block above',
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
  -- mini.ai - new textobjects
  {
    'echasnovski/mini.ai',
    keys = {
      { 'a', mode = { 'x', 'o' } },
      { 'i', mode = { 'x', 'o' } },
    },
    dependencies = { 'nvim-treesitter-textobjects' },
    opts = function()
      local ts = require('mini.ai').gen_spec.treesitter
      return {
        n_lines = 500,
        custom_textobjects = {
          -- b = false, -- = ([{
          q = false, -- = `'"
          -- functions
          F = ts({
            a = { '@function.outer' }, -- entire declaration
            i = { '@function.inner' }, -- body
          }, {}),
          f = ts({
            a = { '@call.outer' }, -- line with the call
            i = { '@call.inner' }, -- arguments
          }),
          a = ts({
            a = { '@parameter.outer' }, -- with comma
            i = { '@parameter.inner' }, -- only parameter itself
          }),
          -- there are not really used
          e = ts({
            a = { '@assignment.outer' }, -- entire assigment line
            i = { '@assignment.rhs' }, -- only the rhs
          }),
          r = ts({
            a = { '@return.outer' }, -- entire return line
            i = { '@return.inner' }, -- only the return value
          }),
          -- ~~~~~~~~~~~~~~~~~~~~~ misc ~~~~~~~~~~~~~~~~~~~~~~ --
          b = ts({ -- code blocks in markdown (custom query)
            a = { '@code_block.outer' },
            i = { '@code_block.inner' },
          }),
          s = ts({ -- structs/classes; instance/definition
            a = { '@class.outer' },
            i = { '@class.inner' },
          }, {}),
          c = ts({ -- inner doesn't work with most languages, use outer
            a = { '@comment.outer' },
            i = { '@comment.inner' },
          }),
          o = ts({ -- any other blocks
            a = { '@block.outer', '@conditional.outer', '@loop.outer', '@frame.outer' },
            i = { '@block.inner', '@conditional.inner', '@loop.inner', '@frame.inner' },
          }, {}),
        },
        silent = true,
      }
    end,
  },
  {
    'windwp/nvim-ts-autotag',
    ft = { 'html', 'xml', 'jsx', 'javascript' }, -- more are available
    opts = {},
  },
}
