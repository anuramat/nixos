{
  plugins = {
    lsp.servers = {
      superhtml.enable = true; # html lsp
      stylelint_lsp.enable = true; # css linter
      biome.enable = true; # web linter/formatter
    };
    ts-autotag = {
      enable = true;
    };
    # TODO
    # conform-nvim.settings.formatters_by_ft.html = [
    #   "prettier"
    # ];
    conform-nvim.settings.formatters_by_ft.javascript = [
      "biome-check"
    ];
  };
}
