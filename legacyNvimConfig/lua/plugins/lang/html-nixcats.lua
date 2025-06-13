return {
  {
    'nvim-ts-autotag',
    ft = { 'html', 'xml', 'jsx', 'javascript' }, -- more are available
    after = function() require('nvim-ts-autotag').setup({}) end,
  },
}
