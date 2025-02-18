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
    'jmbuhr/otter.nvim',
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
    },
    opts = {},
    keys = u.wrap_lazy_keys({
      {
        'o',
        function()
          require('otter').activate()
        end,
        desc = 'activate',
      },
      {
        'O',
        function()
          require('otter').deactivate()
        end,
        desc = 'deactivate',
      },
    }, {
      desc_prefix = 'otter: ',
      lhs_prefix = '<localleader>',
      ft = { 'markdown', 'quarto' },
    }),
  },
  {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' },
    ft = { 'markdown', 'quarto' },
    opts = {
      pipe_table = {
        enabled = false,
      },
      latex = {
        enabled = false,
      },
    },
  },
  {
    '3rd/image.nvim',
    -- TODO check if build and processor are required
    build = false,
    opts = {
      backend = 'kitty',
      processor = 'magick_cli',
    },
    branch = 'master',
  },
  -- TODO figure out proper latex
  {
    'Prometheus1400/markdown-latex-render.nvim',
    dependencies = { '3rd/image.nvim', 'nvim-lua/plenary.nvim' },
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
    keys = u.wrap_lazy_keys({
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
        desc = 'run all above including current one',
      },
      {
        'b',
        function()
          require('quarto.runner').run_below()
        end,
        desc = 'run all below including current one',
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
      ft = { 'markdown', 'quarto' },
      wrapped = {
        {
          '<localleader>r',
          function()
            require('quarto.runner').run_range()
          end,
          mode = 'v',
          desc = 'run range',
        },
      },
    }),
  },
}
