{
  pkgs,
  config,
  ...
}:
{
  home.packages = [
    (config.lib.agents.mkSandbox {
      binName = "codex";
      package = pkgs.codex;
      extraRwDirs = [
        "$HOME/.amp"
      ];
    })
  ];
}
