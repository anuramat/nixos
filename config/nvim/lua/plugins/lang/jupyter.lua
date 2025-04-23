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
      vim.g.molten_auto_open_output = false
      vim.g.molten_image_provider = 'image.nvim'
      vim.g.molten_wrap_output = true
      vim.g.molten_virt_text_output = true
      -- vim.g.molten_virt_lines_off_by_1 = true
    end,
  },
}
