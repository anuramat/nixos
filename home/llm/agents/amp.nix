{
  pkgs,
  config,
  ...
}:
{
  home.packages = [
    (config.lib.agents.mkSandbox {
      package = pkgs.amp;
      extraRwDirs = [
        "$HOME/.amp"
      ];
    })
  ];
}
