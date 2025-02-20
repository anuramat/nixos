return {
  -- project wide find and replace
  {
    'MagicDuck/grug-far.nvim',
    opts = {},
    cmd = 'GrugFar',
    keys = {},
  },
  -- compiler.nvim
  {
    'Zeioth/compiler.nvim',
    cmd = { 'CompilerOpen', 'CompilerToggleResults', 'CompilerRedo' },
    dependencies = { 'stevearc/overseer.nvim' },
    opts = {},
    -- TODO steal more shit from https://github.com/Zeioth/compiler.nvim
  },
  -- overseer.nvim - task runner (tasks.json, dap integration, etc)
  {
    'stevearc/overseer.nvim',
    commit = '6271cab7ccc4ca840faa93f54440ffae3a3918bd',
    cmd = { 'CompilerOpen', 'CompilerToggleResults', 'CompilerRedo' },
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
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
    opts = function()
      local harpoon = require('harpoon')
      local set = function(lhs, rhs, desc)
        vim.keymap.set('n', '<leader>h' .. lhs, rhs, { silent = true, desc = 'Harpoon: ' .. desc })
      end
   -- stylua: ignore start
    set('a', function() harpoon:list():add() end, 'Add')
    set('l', function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, 'List')
    set('n', function() harpoon:list():next() end, 'Next')
    set('p', function() harpoon:list():prev() end, 'Previous')
      -- stylua: ignore end
      for i = 1, 9 do
        local si = tostring(i)
        set(si, function()
          harpoon:list():select(i)
        end, 'Go to #' .. si)
      end
    end,
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
