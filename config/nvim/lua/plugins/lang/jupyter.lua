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
      -- running is handled by quarto plugin

      -- { 'e', 'MoltenEvaluateOperator', 'evaluate operator' },
      -- { 'ee', 'MoltenEvaluateLine', 'evaluate line' }, -- for some reason doouble operator doesn't make an output
      -- { 'e', moltenVisual, 'run selection', mode = 'v' },
      -- { 'r', 'MoltenReevaluateCell', 'reevaluate cell' },
      --
      -- { 'o', 'MoltenEnterOutput', 'open output window' },
      -- { 'd', 'MoltenDelete', 'delete cell' },

      { 'i', initLatest, 'init with latest kernel' },
    }, {
      desc_prefix = 'molten',
      lhs_prefix = '<leader>m',
      ft = { 'markdown', 'quarto' },
    }),
  },
}
