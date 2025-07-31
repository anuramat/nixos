{
  pkgs,
  config,
  ...
}:
{
  # TODO ALL
  home.packages = [
    (config.lib.agents.mkSandbox {
      package = pkgs.goose;
      wrapperName = "gse";
    })
  ];
}
