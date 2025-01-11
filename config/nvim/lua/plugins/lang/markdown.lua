return {
  {
    'AckslD/nvim-FeMaco.lua',
    opts = {},
    keys = {
      { '<localleader>e', '<cmd>FeMaco<cr>', ft = 'markdown', desc = 'Edit Code Block' },
    },
  },
  {
    'jmbuhr/otter.nvim',
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
    },
    opts = {},
    ft = 'markdown',
    keys = {

      {
        '<localleader>o',
        function()
          require('otter').activate()
        end,
        ft = 'markdown',
        desc = 'Activate Otter',
      },
    },
  },
}
