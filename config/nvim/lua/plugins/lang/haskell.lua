local ul = require('utils.lsp')

local function repl_toggler(ht, buffer)
  return function() ht.repl.toggle(vim.api.nvim_buf_get_name(buffer)) end
end

return {
  'mrcjkb/haskell-tools.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
  },
  ft = { 'haskell', 'lhaskell', 'cabal', 'cabalproject' },
  config = function()
    vim.g.haskell_tools = {
      hls = {
        capabilities = require('blink.cmp').get_lsp_capabilities(),
        on_attach = function(client, buffer, ht)
          ul.on_attach(client, buffer)

          local s = function(lhs, rhs, desc)
            vim.keymap.set('n', '<localleader>' .. lhs, rhs, { buffer = buffer, desc = 'Haskell: ' .. desc })
          end

          s('b', repl_toggler(ht, buffer), 'Toggle Buffer REPL')
          s('e', ht.lsp.buf_eval_all, 'Evaluate All')
          s('h', ht.hoogle.hoogle_signature, 'Show Hoogle Signature')
          s('p', ht.repl.toggle, 'Toggle Package REPL')
          s('q', ht.repl.quit, 'Quit REPL')

          ht.dap.discover_configurations(buffer, { autodetect = true, settings_file_pattern = 'launch.json' })
        end,
      },
    }
  end,
}
