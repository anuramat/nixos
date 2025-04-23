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
    -- TODO figure out proper latex
    -- this uses a weird matplotlib hack
    'Prometheus1400/markdown-latex-render.nvim',
    dependencies = { '3rd/image.nvim', 'nvim-lua/plenary.nvim' },
    enabled = false,
    build = 'make install',
    lazy = false,
    branch = 'main',
    opts = {
      usetex = true,
      preamble = (function()
        local path = vim.fn.expand('$XDG_CONFIG_HOME') .. '/latex/preamble.tex'
        local file = io.open(path, 'r')
        if file ~= nil then
          local preamble = file:read('*a')
          file:close()
          return preamble
        end
      end)(),
    },
  },
}
