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
  inherit (config.lib.agents) roles mkPrompts;
  subagents = mkPrompts "opencode/agent" roles;
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
    # Lsp
    activation = {
      opencodeConfig = config.lib.home.jsonUpdate {
        "." = settings;
      } "${config.xdg.configHome}/opencode/opencode.json";
    };
  };

  # parametrize agent header, then uncomment TODO
  # https://opencode.ai/docs/agents/
  # xdg.configFile = { } // subagents;
}
