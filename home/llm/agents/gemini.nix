{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (config.lib) agents;
in
{
  home = {
    file = {
      ".gemini/GEMINI.md".text = agents.systemPrompt;
      ".gemini/settings.json".text = lib.generators.toJSON { } {
        contextFileName = [
          "GEMINI.md"
          "CLAUDE.md"
          "AGENTS.md"
        ];
      };
    };

    packages = [
      (config.lib.agents.mkSandbox {
        package = pkgs.gemini-cli;
        wrapperName = "gmn";
        agentDir = null;
        extraRwDirs = [
          "$HOME/.gemini"
        ];
      })
    ];
  };
}
