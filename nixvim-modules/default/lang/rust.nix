{
  plugins = {
    lint.lintersByFt.rust = [ "clippy" ];
    conform-nvim.settings.formatters_by_ft.rust = [
      "rustfmt"
    ];
    rustaceanvim = {
      enable = true;
    };
  };
}
