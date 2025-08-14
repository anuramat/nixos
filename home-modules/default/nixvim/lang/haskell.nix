{
  # TODO haskell tools
  plugins = {
    lsp.servers.hls = {
      enable = true;
      installGhc = true;
    };
    conform-nvim.settings.formatters_by_ft.haskell = [ "ormolu" ];
  };
}
