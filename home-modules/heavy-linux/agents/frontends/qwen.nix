{
  pkgs,
  config,
  ...
}:
let
  inherit (config.lib) agents;
  contextFileName = "AGENTS.md";
  qwenConfig = config.lib.home.json.set {
    inherit contextFileName;
    hideTips = true;
    hideBanner = true;
  } (config.home.homeDirectory + "/.qwen/settings.json");
  pkg = config.lib.agents.mkPackages {
    package = pkgs.qwen-code;
    args = "--yolo";
    agentDir = null;
    extraRwDirs = [
      "$HOME/.qwen"
    ];
  };

in
{
  home = {
    activation = {
      inherit qwenConfig;
    };
    file.".qwen/${contextFileName}".text = agents.instructions.generic;
    packages = [ pkg ];
  };
}
