-- vim: fdl=1
return {
  -- rainbow-delimiters.nvim - TS rainbow parentheses
  {
    -- alterntaive: <https://github.com/saghen/blink.pairs>
    'HiPhish/rainbow-delimiters.nvim',
    dependencies = 'nvim-treesitter/nvim-treesitter',
    event = 'BufEnter',
  },
  -- dressing.nvim -- vim.ui.select (choice menus), vim.ui.input (lsp rename)
  {
    'stevearc/dressing.nvim',
    opts = {},
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
    opts = {
      signs = false,
      highlight = {
        keyword = 'bg', -- only highlight the word
        pattern = [[<(KEYWORDS)>]], -- vim regex
        multiline = false,
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
    branch = 'master', -- until 7c651c0185bfe712948f8c4e21eb3ca495e4faa5 gets merged in
    config = {
      autocmd = { enabled = true },
      ignore = {
        ft = { 'markdown' },
      },
    },
  },
  -- figlet based greeter
  {
    'anuramat/figtree.nvim',
    priority = 999,
    lazy = false,
    dev = false,
    opts = {},
  },
}
