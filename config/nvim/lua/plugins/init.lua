local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'

if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', -- latest stable release
    lazypath,
  })
end



vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
{ import = 'plugins.ui' },
{ import = 'plugins.dap' },
{ import = 'plugins.lsp' },
{ import = 'plugins.misc' },
{ import = 'plugins.extensions' },
{ import = 'plugins.treesitter' },
{ import = 'plugins.specific' },
{ import = 'plugins.interface' },
}, {
  change_detection = {
    enabled = false,
  },
  defaults = {
    lazy = true,
    cond = not vim.g.vscode,
  },
  ui = {
    border = vim.g.border,
  },
})
