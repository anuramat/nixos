{
  pkgs,
  config,
  ...
}:
{
  home.packages = [
    pkgs.goose-cli
    (config.lib.agents.mkSandbox {
      package = pkgs.goose-cli;
      wrapperName = "gse";
    })
  ];
}
