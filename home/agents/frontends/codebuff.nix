{
  pkgs,
  config,
  ...
}:
{
  home.packages = [
    (config.lib.agents.mkSandbox {
      package = pkgs.codebuff;
      wrapperName = "cbf";
    })
  ];
}
