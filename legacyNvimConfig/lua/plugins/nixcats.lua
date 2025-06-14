local u = require('utils.helpers')

vim.g.lze = {
  verbose = false,
  load = vim.cmd.packadd,
  default_priority = 50,
}

-- Configure lze with our plugins
require('lze').load({
  -- TreeSJ - splits/joins code
  {
    'treesj',
    after = function()
      require('treesj').setup({
        use_default_keymaps = false,
        max_join_length = 500,
      })
    end,
    keys = {
      {
        '<leader>j',
        function() require('treesj').toggle() end,
        desc = 'TreeSJ: Split/Join a Treesitter node',
      },
    },
  },

  -- Flash.nvim - jump around
  {
    'flash.nvim',
    after = function()
      require('flash').setup({
        modes = {
          char = {
            enabled = false,
          },
          treesitter = {
            label = {
              rainbow = { enabled = true },
            },
          },
        },
        label = {
          before = true,
          after = false,
        },
      })
    end,
    keys = {
      {
        '<leader>r',
        mode = 'n',
        function() require('flash').jump() end,
        desc = 'Jump',
      },
      {
        'r',
        mode = 'o',
        function() require('flash').treesitter() end,
        desc = 'TS node',
      },
    },
  },

  -- Undotree
  {
    'undotree',
    cmd = {
      'UndotreeHide',
      'UndotreeShow',
      'UndotreeFocus',
      'UndotreeToggle',
    },
    keys = {
      {
        '<leader>u',
        '<cmd>UndotreeToggle<cr>',
        desc = 'Undotree',
      },
    },
  },

  -- Wastebin
  {
    'wastebin.nvim',
    after = function()
      require('wastebin').setup({
        url = 'https://bin.ctrl.sn',
        open_cmd = '__wastebin() { wl-copy "$1" && xdg-open "$1"; }; __wastebin',
        ask = false,
      })
    end,
    keys = {
      { '<leader>w', '<cmd>WastePaste<cr>' },
      { '<leader>w', [[<cmd>'<,'>WastePaste<cr>]], mode = 'v' },
    },
  },

  -- Load other plugin modules
  require('plugins.adapters.cmp-nixcats'),
  require('plugins.adapters.lsp-nixcats'),
  require('plugins.adapters.dap-nixcats'),
  require('plugins.adapters.treesitter-nixcats'),
  require('plugins.adapters.llm-nixcats'),
  require('plugins.adapters.null-nixcats'),
  require('plugins.lang.jupyter-nixcats'),
  require('plugins.lang.c-nixcats'),
  require('plugins.lang.go-nixcats'),
  require('plugins.lang.haskell-nixcats'),
  require('plugins.lang.html-nixcats'),
  require('plugins.lang.lua-nixcats'),
  require('plugins.lang.markdown-nixcats'),
  require('plugins.core.git-nixcats'),
  require('plugins.core.ui-nixcats'),
  require('plugins.core.rare-nixcats'),
})
