-- TODO docstring
--- default on_attach
--- creates autoformat autocommand, toggling commands
return function(client, buffer)
  require('utils.lsp.keys').setup_lsp_keybinds(buffer)
  require('utils.lsp.formatting').setup_lsp_autoformatting(client, buffer)
end