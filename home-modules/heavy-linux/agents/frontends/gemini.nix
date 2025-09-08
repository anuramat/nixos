{
  pkgs,
  config,
  ...
}:
let
  inherit (config.lib) agents;
  contextFileName = "AGENTS.md";
  geminiConfig = config.lib.home.json.set {
    inherit contextFileName;
    hideTips = true;
    hideBanner = true;
  } (config.home.homeDirectory + "/.gemini/settings.json");
in
{
  home = {
    activation = {
      inherit geminiConfig;
    };
    file.".gemini/${contextFileName}".text = agents.instructions.generic;
    packages = config.lib.agents.mkPackages {
      package = pkgs.gemini-cli;
      wrapperName = "gmn";
      args = "--yolo";
      agentDir = null;
      extraRwDirs = [
        "$HOME/.gemini"
      ];
    };
  };
}
