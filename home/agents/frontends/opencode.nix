{
  pkgs,
  hax,
  lib,
  config,
  ...
}:
let
  settings = {
    instructions = config.lib.agents.contextFiles;
  };
in
{
  home = {
    packages = [
      (config.lib.agents.mkSandbox {
        wrapperName = "ocd";
        package = pkgs.opencode;
      })
    ];
    # TODO mcp
    # TODO subasians
    # TODO commands
    activation = {
      opencodeConfig = config.lib.home.jsonUpdate {
        "." = settings;
      } "${config.xdg.configHome}/opencode/opencode.json";
    };
  };
}
