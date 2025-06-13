-- vim: fdl=1
return {
  {
    '3rd/image.nvim',
    build = false,
    opts = {
      backend = 'kitty',
      processor = 'magick_cli',
    },
    branch = 'master',
  },
  'nvim-lua/plenary.nvim',
  'nvim-tree/nvim-web-devicons',
}
