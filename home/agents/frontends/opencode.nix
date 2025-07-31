{
  pkgs,
  hax,
  lib,
  config,
  ...
}:
let
  settings = {
    instructions = config.lib.agents.contextFileName;
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
      opencodeConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] (
        hax.common.jsonUpdate pkgs "${config.xdg.configHome}/opencode/opencode.json" [
          {
            prop = ".";
            text = lib.generators.toJSON { } settings;
          }
        ]
      );
    };
  };
}
