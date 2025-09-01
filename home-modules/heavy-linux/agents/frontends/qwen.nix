{
  pkgs,
  config,
  ...
}:
# let
#   inherit (config.lib) agents;
#
#   contextFileName = "AGENTS.md";
#   geminiConfig = config.lib.home.json.set {
#     inherit contextFileName;
#   } (config.home.homeDirectory + "/.gemini/settings.json");
#
# in
{
  # home = {
  #   activation = {
  #     inherit
  #       geminiConfig
  #       ;
  #   };
  #   file.".gemini/${contextFileName}".text = agents.instructions.generic;

    packages = [
      pkgs.qwen
      (config.lib.agents.mkSandbox {
        package = pkgs.qwen;
        wrapperName = "qwn";
        args = "--yolo";
        agentDir = null;
        # extraRwDirs = [
        #   "$HOME/.gemini"
        # ];
      })
    ];
  };
}
