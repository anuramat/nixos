local u = require('utils.helpers')

---@param kernelType "localhost"|"file"
---@return function init
local function mkInit(kernelType)
  return function()
    if kernelType == 'localhost' then
      vim.cmd('MoltenInit http://localhost:8888')
    elseif kernelType == 'file' then
      local share = os.getenv('XDG_DATA_HOME')
      local path = share .. '/jupyter/runtime/'

      local kernel = ''

      local handle = io.popen('ls -t ' .. path .. 'kernel-*.json 2>/dev/null')
      if not handle then return nil end
      kernel = handle:read('*l')
      handle:close()

      vim.cmd('MoltenInit ' .. kernel)
    else
      error('illegal kernel type init')
    end
    require('otter').activate()
  end
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
    -- version = '^1.0.0', -- use version <2.0.0 to avoid breaking changes
    branch = 'main',
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
      -- TODO fix export
      { 'd', 'MoltenDelete', 'delete cell' },
      { 'i', mkInit('localhost'), 'init and start otter' },
    }, {
      desc_prefix = 'molten',
      lhs_prefix = '<localleader>',
      ft = { 'markdown', 'quarto' },
      wrapped = {
        { '<a-j>', 'MoltenNext', 'jump to next cell' },
        { '<a-k>', 'MoltenPrev', 'jump to prev cell' },
      },
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
