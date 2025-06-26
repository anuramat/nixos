{ hax, ... }:
{
  keymaps =
    let
      inherit (hax.vim) lua;
      set = key: hax.vim.set ("gr" + key);
    in
    [
      (set "d" (lua "vim.lsp.buf.declaration") "Goto Declaration")
      (set "t" (lua "vim.lsp.buf.type_definition") "Goto Type Definition")
      (set "q" (lua "vim.diagnostic.setqflist") "Diagnostic QF List")
      (set "l" (lua "vim.lsp.codelens.run") "CodeLens")
    ];
  plugins = {
    lsp = {
      enable = true;
      inlayHints = false;
      onAttach = # lua
        ''
          if vim.o.ft == 'markdown' then require('otter').activate() end
        '';
    };
    otter = {
      enable = true;
      settings = {
        handle_leading_whitespace = true;
      };
      autoActivate = false;
    };
  };
}
