# configured: 2025-08-04
{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (config.lib) agents;

  geminiGeneralCfg = config.lib.home.json.set {
    contextFileName = config.lib.agents.contextFiles;
  } (config.home.homeDirectory + "/.gemini/settings.json");

  geminiContextCfg = config.lib.home.json.merge {
    "" = {
      hideTips = true;
      hideBanner = true;
    };
  } (config.home.homeDirectory + "/.gemini/settings.json");

  geminiInstructions = {
    ".gemini/GEMINI.md".text = agents.instructions.text;
  };
in
{
  home = {
    activation = {
      inherit
        geminiGeneralCfg
        geminiContextCfg
        ;
    };
    file = geminiInstructions;

    packages = [
      pkgs.gemini-cli
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
