{
  plugins = {
    # NOTE clippy and cargofmt already in somehow
    crates = {
      enable = true;
    };
    rustaceanvim = {
      enable = true;
      settings.server.default_settings = {
        references = {
          excludeTests = true;
          excludeImports = true;
        };
      };
    };
  };
}
