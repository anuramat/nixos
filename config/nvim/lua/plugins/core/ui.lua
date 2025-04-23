-- vim: fdl=1
return {
  -- rainbow-delimiters.nvim - TS rainbow parentheses
  {
    -- alterntaives:
    -- * https://github.com/luochen1990/rainbow -- 1.7k stars
    -- * https://github.com/junegunn/rainbow_parentheses.vim -- junegunn, seems "complete", 374 stars
    -- * blink.delimiters
    'HiPhish/rainbow-delimiters.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    event = 'BufEnter',
  },
  -- dressing.nvim - input/select ui elements
  {
    -- primarily used in symbol rename
    'stevearc/dressing.nvim',
    opts = {
      input = {
        insert_only = true,
        border = vim.g.border,
      },
      select = {
        backend = { 'builtin', 'nui' },
        nui = { border = { style = vim.g.border } },
        builtin = { border = vim.g.border },
      },
    },
    event = 'VeryLazy',
  },
  -- nvim-colorizer.lua - highlights colors, eg #012345
  {
    'NvChad/nvim-colorizer.lua',
    ft = { 'markdown', 'html', 'css' },
    opts = {},
  },
  -- neopywal.nvim
  {
    'RedsXDD/neopywal.nvim',
    name = 'neopywal',
    lazy = false,
    priority = 1000,
    config = function()
      local neopywal = require('neopywal')
      neopywal.setup({
        use_wallust = true,
        transparent_background = true, -- changes the look even with alpha=100
        dim_inactive = true,
        show_end_of_buffer = true,
        show_split_lines = true,
      })
      vim.cmd.colorscheme('neopywal')
    end,
  },
  -- todo-comments.nvim - highlights "todo", "hack", etc
  {
    'folke/todo-comments.nvim',
    event = 'VeryLazy',
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = {
      signs = false,
      highlight = {
        keyword = 'bg', -- only highlight the word
        pattern = [[<(KEYWORDS)>]], -- vim regex
        multiline = false, -- enable multine todo comments
      },
      search = {
        pattern = [[\b(KEYWORDS)\b]], -- ripgrep regex
      },
    },
  },
  -- lightbulb - code action indicator
  {
    'kosayoda/nvim-lightbulb',
    event = 'LspAttach',
    config = {
      autocmd = { enabled = true },
      ignore = {
        ft = { 'markdown' },
      },
    },
  },
  -- images using kitty protocol
  {
    '3rd/image.nvim',
    build = false,
    opts = {
      backend = 'kitty',
      processor = 'magick_cli',
    },
    branch = 'master',
  },
}
