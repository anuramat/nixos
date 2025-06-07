vim.cmd('runtime base.vim')
vim.diagnostic.config({
  severity_sort = true, -- sort diagnostics by severity
  update_in_insert = true, -- update diagnostics in insert/replace mode
  signs = false,
})
vim.deprecate = function() end -- shut up
-- require('plugins') -- Removed lazy.nvim initialization
require('lze').load(require('lze_specs')) -- Initialize LZE
