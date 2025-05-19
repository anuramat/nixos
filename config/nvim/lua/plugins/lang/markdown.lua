local u = require('utils.helpers')

return {
  {
    'dhruvasagar/vim-table-mode',
    init = function()
      -- vim.g.table_mode_disable_mappings = 1
      -- vim.g.table_mode_disable_tableize_mappings = 1
      vim.g.table_mode_corner = '|'
      -- vim.keymap.set('n', '<leader>T', '<cmd>TableModeToggle<cr>', { silent = true, desc = 'Table Mode: Toggle' })
      -- vim.keymap.set(
      --   'n',
      --   '<leader>t',
      --   '<cmd>TableModeRealign<cr>',
      --   { silent = true, desc = 'Table Mode: Realign once' }
      -- )
    end,
    ft = 'markdown',
  },
  {
    'AckslD/nvim-FeMaco.lua',
    opts = {},
    keys = {
      { '<localleader>e', '<cmd>FeMaco<cr>', ft = 'markdown', desc = 'Edit Code Block' },
    },
  },
  {
    -- uses mathjax
    'anuramat/mdmath.nvim',
    dependencies = 'nvim-treesitter/nvim-treesitter',
    ft = 'markdown',
    opts = {
      preamble = (function()
        local filename = vim.fn.expand('$XDG_CONFIG_HOME/latex/mathjax_preamble.tex')
        local file = io.open(filename, 'r')
        local chars = ''
        if file ~= nil then
          chars = file:read('*a')
          file:close()
        end
        return chars
      end)(),
    },
  },
}
