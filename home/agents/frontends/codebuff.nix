{
  pkgs,
  config,
  ...
}:
{
  home.packages = [
    pkgs.codebuff
    (config.lib.agents.mkSandbox {
      package = pkgs.codebuff;
      wrapperName = "cbf";
    })
  ];
}
