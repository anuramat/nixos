{
  pkgs,
  config,
  ...
}:
{
  home.packages = [
    (config.lib.agents.mkSandbox {
      package = pkgs.codex;
      extraRwDirs = [
        "$HOME/.amp"
      ];
    })
  ];
}
