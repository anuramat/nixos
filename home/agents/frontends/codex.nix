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
      args = "--full-auto";
      # https://github.com/openai/codex/blob/main/codex-rs/config.md
      extraRwDirs = [
      ];
    })
  ];
}
