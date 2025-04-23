local u = require('utils.helpers')

local function initLatest()
  local share = os.getenv('XDG_DATA_HOME')
  local path = share .. '/jupyter/runtime/'

  local kernel = ''

  local handle = io.popen('ls -t ' .. path .. 'kernel-*.json 2>/dev/null')
  if not handle then return nil end
  kernel = handle:read('*l')
  handle:close()

  vim.cmd('MoltenInit ' .. kernel)
end

local function initLatestWithOtter()
  initLatest()
  require('otter').activate()
end

local function moltenVisual()
  local start_line = vim.fn.line('v')
  local end_line = vim.fn.line('.')
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end
  vim.fn.MoltenEvaluateRange(start_line, end_line)
end

return {
  {
    'GCBallesteros/jupytext.nvim',
    lazy = false,
    opts = {
      -- markdown, because jupytext quarto conversion is slower
      style = 'markdown',
      output_extension = 'md', -- default: searches for py, creates md
      force_ft = 'markdown', -- defaults to kernel language
    },
  },
  {
    'benlubas/molten-nvim',
    version = '^1.0.0', -- use version <2.0.0 to avoid breaking changes
    build = ':UpdateRemotePlugins',
    dependencies = {
      '3rd/image.nvim',
      'quarto-dev/quarto-nvim',
    },
    init = function()
      vim.g.molten_auto_open_output = true
      vim.g.molten_image_provider = 'image.nvim'
      vim.g.molten_wrap_output = true
      vim.g.molten_virt_text_output = false
    end,
    keys = u.wrap_lazy_keys({
      { 'e', 'MoltenEvaluateOperator', 'evaluate operator' },
      { 'ee', 'MoltenEvaluateLine', 'evaluate line' }, -- for some reason doouble operator doesn't make an output
      { 'e', moltenVisual, 'run selection', mode = 'v' },
      { 'r', 'MoltenReevaluateCell', 'reevaluate cell' },

      { 'i', initLatestWithOtter, 'init with latest kernel' },
    }, {
      desc_prefix = 'molten',
      lhs_prefix = '<localleader>',
      ft = { 'markdown', 'quarto' },
    }),
  },
  {
    'jmbuhr/otter.nvim',
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
    ft = { 'markdown', 'quarto' },
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
      { 'e', function(m) m.run_range() end, 'run range', mode = 'v' },
    }, {
      lhs_prefix = '<localleader>',
      desc_prefix = 'quarto',
      ft = { 'markdown', 'quarto' },
      module = 'quarto.runner',
    }),
  },
}
