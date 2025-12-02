{
  pkgs,
  config,
  ...
}:

let
  inherit (config.lib) agents;
  contextFileName = "AGENTS.md";
  geminiHome = config.home.homeDirectory + "/.gemini";
  cfgFile = config.lib.home.json.set {
    general = {
      previewFeatures = true;
      disableAutoUpdate = true;
      sessionRetention = {
        enabled = true;
      };
      enablePromptCompletion = true;
    };
    output = {
      format = "text";
    };
    ui = {
      showStatusInTitle = false;
      hideTips = false;
      hideBanner = true;
      footer = {
        hideCWD = false;
        hideContextPercentage = false;
      };
      showMemoryUsage = true;
      showCitations = true;
      showModelInfoInChat = true;
      hideWindowTitle = true;
      useAlternateBuffer = true;
    };
    tools = {
      shell = {
        showColor = true;
      };
      autoAccept = true;
    };
  } (geminiHome + "/settings.json");
  pkg = config.lib.agents.mkPackages {
    package = pkgs.gemini-cli;
    args = [ "--yolo" ];
    agentDir = null;
    extraRwDirs = [
      geminiHome
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
