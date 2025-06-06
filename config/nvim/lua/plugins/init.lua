local u = require('utils.helpers')

local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system({ 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { 'Failed to clone lazy.nvim:\n', 'ErrorMsg' },
      { out, 'WarningMsg' },
      { '\nPress any key to exit...' },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

vim.opt.rtp:prepend(lazypath)

local username = os.getenv('USER')
local remote = 'github.com' -- TODO somehow abstract away? hide in nix maybe

require('lazy').setup({
  { import = 'plugins.core' },
  { import = 'plugins.adapters' },
  { import = 'plugins.lang' },
}, {
  change_detection = {
    enabled = false,
  },
  defaults = {
    lazy = true,
    cond = not vim.g.vscode,
    version = '*', -- nil for latest, * for latest stable semver
  },
  dev = {
    path = vim.fs.joinpath(u.ghq_root(), remote, username),
    patterns = { username },
    fallback = true,
  },
})
