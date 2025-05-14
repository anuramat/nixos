local m = {}

local function set_lsp_keys(buffer)
  local function set(keys, func, desc) vim.keymap.set('n', keys, func, { buffer = buffer, desc = 'LSP: ' .. desc }) end

  set('grd', vim.lsp.buf.declaration, 'Goto Declaration')
  set('grt', vim.lsp.buf.type_definition, 'Goto Type Definition')
  set('grq', vim.diagnostic.setqflist, 'Diagnostic QF List')
  set('grl', vim.lsp.codelens.run, 'CodeLens')

  -- taken care of by mini.bracketed
  -- set('[d', vim.diagnostic.goto_prev, 'Previous Diagnostic')
  -- set(']d', vim.diagnostic.goto_next, 'Next Diagnostic')
end

m.on_attach = function(client, buffer)
  set_lsp_keys(buffer)
  require('lsp-format').on_attach(client, buffer)
  vim.lsp.inlay_hint.enable()
end

m.capabilities = function()
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  return require('blink.cmp').get_lsp_capabilities(capabilities)
end

return m
