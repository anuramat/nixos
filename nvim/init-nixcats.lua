vim.cmd('runtime base.vim')

vim.diagnostic.config({
  severity_sort = true,
  update_in_insert = true,
  signs = false,
})

-- vim.deprecate = function() end -- shut up

if nixCats('lazy') then require('plugins.nixcats') end
