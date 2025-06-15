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

--- Root directory function with a fallback
--- @param opts { primary: string[], fallback: string[] }
m.root_dir_with_fallback = function(opts)
  --- @param fname string Filename
  return function(fname)
    local primary_root = vim.fs.root(fname, opts.primary)
    local fallback_root = vim.fs.root(fname, opts.fallback)
    return primary_root or fallback_root
  end
end

return m
