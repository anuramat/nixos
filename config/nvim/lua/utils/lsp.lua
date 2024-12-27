local M = {}

local function set_lsp_keys(buffer)
  local function set(keys, func, desc)
    vim.keymap.set('n', keys, func, { buffer = buffer, desc = 'LSP: ' .. desc })
  end
  local function set_prefixed(keys, func, desc)
    vim.keymap.set('n', '<leader>l' .. keys, func, { buffer = buffer, desc = 'LSP: ' .. desc })
  end

  local function list_workspace_folders()
    vim.print(vim.lsp.buf.list_workspace_folders())
  end

  local function references()
    vim.lsp.buf.references({ includeDeclaration = false })
  end

  vim.bo[buffer].omnifunc = 'v:lua.vim.lsp.omnifunc'

  set_prefixed('r', vim.lsp.buf.rename, 'Rename symbol')
  set_prefixed('f', vim.lsp.buf.format, 'Format buffer')
  set_prefixed('a', vim.lsp.buf.code_action, 'Code action')
  set_prefixed('l', vim.lsp.codelens.run, 'CodeLens')

  set('gd', vim.lsp.buf.definition, 'Goto Definition') -- prototype: goto local declaration

  set('gD', vim.lsp.buf.declaration, 'Goto Declaration') -- prototype: goto global declaration
  set('gi', vim.lsp.buf.implementation, 'Goto Implementation') -- shadows: insert mode in the last insert mode position
  set('go', vim.lsp.buf.type_definition, 'Goto Type Definition') -- shadows: go to nth byte
  set('gr', references, 'Quickfix References') -- shadows: virtual replace single char
  set('gs', vim.lsp.buf.signature_help, 'Signature Help') -- shadows: sleep
  set('[d', vim.diagnostic.goto_prev, 'Previous Diagnostic') -- shadows: goto first macro definition
  set(']d', vim.diagnostic.goto_next, 'Next Diagnostic') -- shadows: goto next macro definition

  set_prefixed('q', vim.diagnostic.setloclist, 'Diagnostic Loc List')
  set_prefixed('Q', vim.diagnostic.setqflist, 'Diagnostic QF List')

  set_prefixed('wa', vim.lsp.buf.add_workspace_folder, 'Add Workspace Folder')
  set_prefixed('wr', vim.lsp.buf.remove_workspace_folder, 'Remove Workspace Folder')
  set_prefixed('wl', list_workspace_folders, 'List Workspace Folders')
end

M.on_attach = function(client, buffer)
  set_lsp_keys(buffer)
  require('lsp-format').on_attach(client, buffer)
  vim.lsp.inlay_hint.enable()
end

return M
