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
  } (config.home.homeDirectory + "/.qwen/settings.json");
in
{
  home = {
    activation = {
      inherit qwenConfig;
    };
    file.".qwen/${contextFileName}".text = agents.instructions.generic;
    packages = [
      pkgs.qwen-code
      (config.lib.agents.mkSandbox {
        package = pkgs.qwen-code;
        wrapperName = "qwn";
        args = "--yolo";
        agentDir = null;
        extraRwDirs = [
          "$HOME/.qwen"
        ];
      })
    ];
  };
}
