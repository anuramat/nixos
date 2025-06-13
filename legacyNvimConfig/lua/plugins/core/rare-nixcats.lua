-- vim: fdl=1
local u = require('utils.helpers')

return {
  -- find and replace
  {
    'grug-far.nvim',
    after = function() require('grug-far').setup({}) end,
    cmd = { 'GrugFar', 'GrugFarWithin' },
  },
  -- task runner (tasks.json, dap integration, etc)
  {
    'overseer.nvim',
    event = 'VeryLazy', -- todo use cmd to lazy load
    after = function()
      require('overseer').setup({
        task_list = {
          direction = 'bottom',
          min_height = 25,
          max_height = 25,
          default_detail = 1,
        },
      })
    end,
  },
  -- sniprun - run selected code
  {
    event = 'VeryLazy',
    'sniprun',
    build = 'sh install.sh',
    after = function() require('sniprun').setup({}) end,
  },
  -- harpoon - project-local file marks
  {
    'harpoon',
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
    'namu.nvim',
    after = function()
      require('namu').setup({
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
      })
    end,
    keys = {
      { '<leader>s', '<cmd>Namu symbols<cr>', { desc = 'Jump to LSP symbol', silent = true } },
    },
  },
}
