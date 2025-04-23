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
    lazy = false,
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
    },
    opts = {},
    keys = u.wrap_lazy_keys({
      { 'o', function(m) m.activate() end, 'activate' },
      { 'O', function(m) m.deactivate() end, 'deactivate' },
    }, {
      module = 'otter',
      lhs_prefix = '<localleader>',
      ft = { 'markdown', 'quarto' },
    }),
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
  -- this uses a weird matplotlib hack
  {
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
      { 'c', function(m) m.run_cell() end, 'run cell' },
      { 'a', function(m) m.run_above() end, 'run all above including current one' },
      { 'b', function(m) m.run_below() end, 'run all below including current one' },
      { 'A', function(m) m.run_all() end, 'run all' },
      { 'l', function(m) m.run_line() end, 'run line' },
    }, {
      lhs_prefix = '<localleader>r',
      desc_prefix = 'quarto',
      ft = { 'markdown', 'quarto' },
      module = 'quarto.runner',
      wrapped = {
        {
          '<leader>m',
          function(m) m.run_range() end,
          'run range',
          mode = 'v',
        },
      },
    }),
  },
}
