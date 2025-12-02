{
  pkgs,
  config,
  ...
}:

# "general": {
#   "previewFeatures": true,
#   "disableAutoUpdate": true,
#   "sessionRetention": {
#     "enabled": true
#   },
#   "enablePromptCompletion": true
# },
# "output": {
#   "format": "text"
# },
# "ui": {
#   "showStatusInTitle": false,
#   "hideTips": false,
#   "hideBanner": true,
#   "footer": {
#     "hideCWD": false,
#     "hideContextPercentage": false
#   },
#   "showMemoryUsage": true,
#   "showCitations": true,
#   "showModelInfoInChat": true,
#   "hideWindowTitle": true,
#   "useAlternateBuffer": true
# },
# "tools": {
#   "shell": {
#     "showColor": true
#   },
#   "autoAccept": true
# }

let
  cfg = { };
  inherit (config.lib) agents;
  contextFileName = "AGENTS.md";
  cfgFile = config.lib.home.json.set cfg (config.home.homeDirectory + "/.gemini/settings.json");
  pkg = config.lib.agents.mkPackages {
    package = pkgs.gemini-cli;
    args = [ "--yolo" ];
    agentDir = null;
    extraRwDirs = [
      "$HOME/.gemini"
    ];
  };
in
{
  home = {
    activation = {
      geminiConfig = cfgFile;
    };
    file.".gemini/${contextFileName}".text = agents.instructions.generic;
    packages = [ pkg ];
  };
}
