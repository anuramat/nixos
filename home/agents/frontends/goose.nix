{
  pkgs,
  config,
  ...
}:
{
  # TODO ALL
  home.packages = [
    pkgs.goose
    (config.lib.agents.mkSandbox {
      package = pkgs.goose;
      wrapperName = "gse";
    })
  ];
}
