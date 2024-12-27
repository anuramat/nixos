vim.cmd('runtime base.vim')
vim.diagnostic.config({
  severity_sort = true, -- sort diagnostics by severity
  update_in_insert = true, -- update diagnostics in insert/replace mode
  float = { border = vim.g.border }, -- settings for `vim.diagnostic.open_float`
  signs = false,
})
require('plugins')
require('adhoc')
