-- vim: fdl=1
local function transparent_bg()
  local file = io.open(vim.fn.expand('$XDG_CACHE_HOME/wallust/alpha'), 'r')
  local chars
  if file ~= nil then
    chars = vim.trim(file:read('*a'))
    file:close()
    return chars ~= '100'
  end
  return false
end
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
        transparent_background = transparent_bg(),
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
  {
    'j-hui/fidget.nvim',
    event = 'LspAttach',
    opts = {},
  },
}
