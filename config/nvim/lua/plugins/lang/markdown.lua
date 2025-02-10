local u = require('utils.helpers')

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
  },
  {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' },
    ft = { 'markdown', 'quarto' },
    opts = {
      latex = {
        enabled = false,
      },
    },
  },
  {
    '3rd/image.nvim',
    -- TODO check if build and processor are required
    build = false,
    lazy = false,
    opts = {
      backend = 'kitty',
      processor = 'magick_cli',
    },
    branch = 'master',
  },
  -- TODO figure out proper latex
  -- {
  --   'Prometheus1400/markdown-latex-render.nvim',
  --   dependencies = { '3rd/image.nvim', 'nvim-lua/plenary.nvim' },
  --   build = 'make install',
  --   lazy = false,
  --   branch = 'main',
  --   opts = {
  --     usetex = true,
  --   },
  -- },
  {
    'quarto-dev/quarto-nvim',
    dependencies = {
      'jmbuhr/otter.nvim',
      'nvim-treesitter/nvim-treesitter',
    },
    ft = { 'markdown', 'quarto' },
    branch = 'main',
    opts = {
      closePreviewOnExit = true,
      lspFeatures = {
        languages = { 'python' },
      },
      codeRunner = {
        default_method = 'molten',
      },
    },

    keymaps = u.wrap_lazy_keys({
      {
        'c',
        function()
          require('quarto.runner').run_cell()
        end,
        desc = 'run cell',
      },
      {
        'a',
        function()
          require('quarto.runner').run_above()
        end,
        desc = 'run above',
      },
      {
        'A',
        function()
          require('quarto.runner').run_all()
        end,
        desc = 'run all',
      },
      {
        'l',
        function()
          require('quarto.runner').run_line()
        end,
        desc = 'run line',
      },
    }, {
      lhs_prefix = '<localleader>r',
      desc_prefix = 'quarto: ',
      wrapped = {
        {
          '<localleader>r',
          function()
            require('quarto.runner').run_range()
          end,
          mode = 'v',
          desc = 'quarto: run range',
        },
        {
          '<localleader>o',
          function()
            require('otter').activate()
            require('quarto').activate()
          end,
          -- silent = 'true'
          desc = 'activate otter and quarto',
        },
      },
    }),
  },
}
