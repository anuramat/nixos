{
  pkgs,
  config,
  ...
}:
{
  home.packages = [
    pkgs.forge
    (config.lib.agents.mkSandbox {
      package = pkgs.forge;
      wrapperName = "frg";
    })
  ];
}
