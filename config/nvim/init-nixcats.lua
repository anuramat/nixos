-- nixcats-based init.lua
vim.cmd('runtime base.vim')

vim.diagnostic.config({
  severity_sort = true,
  update_in_insert = true,
  signs = false,
})

vim.deprecate = function() end -- shut up

-- Check if we're running under nixcats
if not nixCats then
  error("This configuration requires nixcats! Please install via the nixcats flake.")
end

-- Only load lazy plugins if the category is enabled
if nixCats('lazy') then
  require('plugins.nixcats')
end