{
  plugins = {
    lsp.servers = {
      superhtml.enable = true; # html lsp
      stylelint_lsp.enable = true; # css linter
      biome.enable = true; # web linter/formatter
      ts_ls.enable = true; # ts/js lsp
    };
    ts-autotag = {
      enable = true;
    };
    # TODO steal from ctrl.sn
    # conform-nvim.settings.formatters_by_ft.html = [
    # ];
    conform-nvim.settings.formatters_by_ft.javascript = [
      "biome-check"
    ];
  };
}
