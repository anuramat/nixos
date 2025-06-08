-- Load base vim configuration
vim.cmd('runtime base.vim')

-- Configure diagnostics
vim.diagnostic.config({
  severity_sort = true, -- sort diagnostics by severity
  update_in_insert = true, -- update diagnostics in insert/replace mode
  signs = false,
})

-- Silence deprecation warnings
vim.deprecate = function() end

-- Check if we're running under nixcats
if nixCats then
  -- We're running under nixcats, use the new configuration
  if nixCats('lazy') then require('plugins.nixcats') end
else
  -- Fallback to old lazy.nvim configuration for development/testing
  require('plugins')
end
