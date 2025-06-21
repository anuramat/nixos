{ pkgs, hax, ... }:
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
  plugins.lsp = {
    enable = true;
    inlayHints = false;
    servers = {
      clangd.enable = true;
      rust_analyzer = {
        enable = true;
        installCargo = false;
        installRustc = false;
      };
      zls.enable = true;
      jsonls = {
        enable = false; # TODO fix
        cmd = [
          "vscode-json-languageserver"
          "--stdio"
        ];
      };
    };
  };
}
