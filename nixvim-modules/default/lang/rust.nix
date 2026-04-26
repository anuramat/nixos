{
  plugins = {
    # NOTE clippy and cargofmt already in somehow
    crates = {
      enable = true;
    };
    rustaceanvim = {
      enable = true;
      settings.server = {
        default_settings = {
          rust_analyzer = {
            references = {
              excludeTests = true;
              excludeImports = true;
            };
          };
        };
      };
    };
  };
}
