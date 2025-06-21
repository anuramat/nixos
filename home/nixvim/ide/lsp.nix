{ pkgs, ... }:
{
  keymaps =
    let
      _mkMap = key: action: desc: {
        mode = "n";
        inherit key action;
        options = { inherit desc; };
      };
      mkMap =
        k: a: d:
        _mkMap ("gr" + k) { __raw = a; } d;
    in
    [
      (mkMap "d" "vim.lsp.buf.declaration" "Goto Declaration")
      (mkMap "t" "vim.lsp.buf.type_definition" "Goto Type Definition")
      (mkMap "q" "vim.diagnostic.setqflist" "Diagnostic QF List")
      (mkMap "l" "vim.lsp.codelens.run" "CodeLens")
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
