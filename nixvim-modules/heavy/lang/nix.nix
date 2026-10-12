{
  plugins = {
    lint.lintersByFt.nix = [
      "statix"
      "deadnix"
    ];
    conform-nvim.settings.formatters_by_ft.nix = [
      "nixfmt"
      "injected"
    ];
    none-ls.sources.code_actions = {
      statix.enable = true;
    };
    lsp.servers = {
      nil_ls.enable = true;
    };
  };
}
