{
  # TODO haskell tools
  plugins = {
    lsp.servers.hls = {
      enable = true;
    };
    conform-nvim.settings.formatters_by_ft.haskell = [ "ormolu" ];
  };
}
