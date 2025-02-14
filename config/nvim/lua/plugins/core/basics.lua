-- vim: fdl=1
return {
  -- aerial.nvim - symbol outline
  {
    -- simrat39/symbols-outline.nvim
    'stevearc/aerial.nvim',
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'nvim-tree/nvim-web-devicons',
    },
    event = 'BufEnter',
    opts = {
      filter_kind = {
        nix = false,
      },
    },
    keys = { { 'gO', '<cmd>AerialToggle!<cr>', desc = 'Show Aerial Outline' } },
  },
  -- lsp-format.nvim
  {
    'lukas-reineke/lsp-format.nvim',
    lazy = false,
    opts = {
      lua = {
        exclude = {
          'lua_ls',
        },
      },
      nix = {
        exclude = {
          'nixd',
          'nil_ls',
        },
      },
    },
  },
  -- vim-sleuth - autodetects indentation settings
  {
    'tpope/vim-sleuth',
    lazy = false,
    enabled = false,
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
          b = false, -- = ([{
          q = false, -- = `'"
          -- ~~~~~~~~~~~~~~~~~~~ functions ~~~~~~~~~~~~~~~~~~~ --
          F = ts({
            a = { '@function.outer' },
            i = { '@function.inner' },
          }, {}),
          f = ts({
            a = { '@call.outer' },
            i = { '@call.inner' },
          }),
          a = ts({
            a = { '@parameter.outer' },
            i = { '@parameter.inner' },
          }),
          -- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ --
          e = ts({
            a = { '@assignment.outer' },
            i = { '@assignment.rhs' },
          }),
          r = ts({
            a = { '@return.outer' },
            i = { '@return.inner' },
          }),
          -- ~~~~~~~~~~~~~~~~~~~~~ misc ~~~~~~~~~~~~~~~~~~~~~~ --
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
  -- mini.bracketed - new ]/[ targets
  {
    'echasnovski/mini.bracketed',
    lazy = false,
    opts = {},
  },
  -- vim-fetch - allows for ':e file.txt:1337'
  {
    lazy = false,
    'wsdjeg/vim-fetch',
  },
  -- surround
  {
    'kylechui/nvim-surround',
    opts = {
      keymaps = {
        insert = '<C-g>s',
        insert_line = '<C-g>S',
        normal = 's',
        normal_cur = 'ss',
        normal_line = 'S',
        normal_cur_line = 'SS',
        visual = 's',
        visual_line = 'S',
        delete = 'ds',
        change = 'cs',
        change_line = 'cS',
      },
    },
    event = 'BufEnter',
  },
}
