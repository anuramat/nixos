-- vim: fdl=1
local u = require('utils.helpers')

return {
  -- find and replace
  {
    'MagicDuck/grug-far.nvim',
    opts = {},
    cmd = { 'GrugFar', 'GrugFarWithin' },
  },
  -- task runner (tasks.json, dap integration, etc)
  {
    'stevearc/overseer.nvim',
    event = 'VeryLazy', -- todo use cmd to lazy load
    opts = {
      task_list = {
        direction = 'bottom',
        min_height = 25,
        max_height = 25,
        default_detail = 1,
      },
    },
  },
  -- sniprun - run selected code
  {
    event = 'VeryLazy',
    'michaelb/sniprun',
    build = 'sh install.sh',
    opts = {},
  },
  -- harpoon - project-local file marks
  {
    'ThePrimeagen/harpoon',
    branch = 'harpoon2',
    keys = u.wrap_lazy_keys({
      { 'a', function(m) m:list():add() end, 'Add' },
      { 'l', function(m) m.ui:toggle_quick_menu(m:list()) end, 'List' },
      { 'n', function(m) m:list():next() end, 'Next' },
      { 'p', function(m) m:list():prev() end, 'Previous' },
      { '%d', function(i, m) m:list():select(i) end, 'Go to #%d', iterator = true },
    }, {
      module = 'harpoon',
      lhs_prefix = '<leader>h',
    }),
  },
  -- namu -- symbols
  {
    'bassamsdata/namu.nvim',
    opts = {
      namu_symbols = {
        enable = true,
        options = {},
      },
      ui_select = {
        enable = true,
      },
      colorscheme = {
        enable = true,
      },
    },
    keys = {
      { '<leader>s', '<cmd>Namu symbols<cr>', { desc = 'Jump to LSP symbol', silent = true } },
    },
  },
}
