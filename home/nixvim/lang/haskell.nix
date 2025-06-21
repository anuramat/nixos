# haskell
# s('b', repl_toggler(ht, buffer), 'Toggle Buffer REPL')
# s('e', ht.lsp.buf_eval_all, 'Evaluate All')
# s('h', ht.hoogle.hoogle_signature, 'Show Hoogle Signature')
# s('p', ht.repl.toggle, 'Toggle Package REPL')
# s('q', ht.repl.quit, 'Quit REPL')
{
  plugins = {
    lsp.servers.hls = {
      enable = true;
    };
    conform-nvim.settings.formatters_by_ft.haskell = [ "ormolu" ];
  };
}
