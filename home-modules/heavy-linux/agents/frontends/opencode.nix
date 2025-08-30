{
  pkgs,
  config,
  ...
}:
{
  # TODO mcp commands hooks modes
  home = {
    packages = [
      pkgs.opencode
      (config.lib.agents.mkSandbox {
        wrapperName = "ocd";
        package = pkgs.opencode;
      })
    ];
    activation = {
      opencodeConfig = config.lib.home.json.set {
        instructions = [ "AGENTS.md" ];
      } "${config.xdg.configHome}/opencode/opencode.json";
    };
  };
  xdg.configFile."opencode/AGENTS.md".text = config.lib.agents.instructions.generic;
}
