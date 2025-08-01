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
      ".gemini/GEMINI.md".text = agents.instructions.text;
      ".gemini/settings.json".text = lib.generators.toJSON { } {
        theme = "Default";
        selectedAuthType = "oauth-personal";
        contextFileName = config.lib.agents.contextFiles;
      };
    };
    packages = [
      (config.lib.agents.mkSandbox {
        package = pkgs.gemini-cli;
        wrapperName = "gmn";
        args = "--yolo";
        agentDir = null;
        extraRwDirs = [
          "$HOME/.gemini"
        ];
      })
    ];
  };
}
