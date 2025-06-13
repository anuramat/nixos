-- vim: fdl=1
local function transparent_bg() return false end -- TODO stylix
return {
  -- rainbow-delimiters.nvim - TS rainbow parentheses
  {
    'HiPhish/rainbow-delimiters.nvim',
    dependencies = 'nvim-treesitter/nvim-treesitter',
    event = 'BufEnter',
    submodules = false,
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
    ft = { 'css', 'yaml' },
    opts = {},
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
    -- conflicts with fzf-lua for some reason
    'anuramat/figtree.nvim',
    enabled = false,
    priority = 999,
    lazy = false,
    dev = false,
    opts = {},
  },
  {
    'j-hui/fidget.nvim',
    event = 'LspAttach',
    opts = {},
  },
}
