return {
  {
    'clangd_extensions.nvim',
    after = function() require('clangd_extensions').setup({}) end,
  },
}
