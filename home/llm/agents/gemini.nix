{
  pkgs,
  config,
  ...
}:
{
  home.packages = [
    (config.lib.agents.mkSandbox {
      package = pkgs.gemini-cli;
      agentDir = null;
      extraRwDirs = [
        "$HOME/.gemini"
        "/etc/gemini-cli"
      ];
    })
  ];
}
