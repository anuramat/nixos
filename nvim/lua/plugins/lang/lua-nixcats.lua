return {
  {
    'lazydev.nvim',
    ft = 'lua', -- only load on lua files
    after = function() require('lazydev').setup({}) end,
  },
}
