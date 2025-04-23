local u = require('utils.helpers')

return {
  {
    'GCBallesteros/jupytext.nvim',
    -- TODO turn this on, figure out loading chain
    lazy = false,
    opts = {
      style = 'markdown',
      output_extension = 'md',
      force_ft = 'markdown',
    },
  },
  {
    'benlubas/molten-nvim',
    -- TODO turn this on
    lazy = false,
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
      { 'o', 'MoltenEnterOutput', 'open output window' },
      { 'e', 'MoltenEvaluateVisual', mode = 'v' }, -- kinda weird, doesn't work half the time
    }, {
      desc_prefix = 'molten',
      lhs_prefix = '<leader>m',
      ft = { 'markdown' },
    }),
  },
}
