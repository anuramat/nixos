vim.cmd('runtime base.vim')
vim.diagnostic.config({
  severity_sort = true, -- sort diagnostics by severity
  update_in_insert = true, -- update diagnostics in insert/replace mode
  float = { border = vim.g.border }, -- settings for `vim.diagnostic.open_float`
  signs = false,
})
vim.deprecate = function() end -- shut up
-- TODO gets stuck sometimes; not that important anyway
-- if os.getenv('SSH_TTY') then
--   vim.g.clipboard = {
--     name = 'OSC 52',
--     copy = {
--       ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
--       ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
--     },
--     paste = {
--       ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
--       ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
--     },
--   }
-- end
require('plugins')
require('adhoc')
