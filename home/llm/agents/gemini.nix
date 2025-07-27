{
  pkgs,
  config,
  ...
}:
{
  home.packages = [
    (config.lib.agents.mkSandbox {
      package = pkgs.gemini-cli;
      wrapperName = "gmn";
      agentDir = null;
      extraRwDirs = [
        "$HOME/.gemini"
      ];
    })
  ];
}
