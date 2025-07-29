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
  agentDir = "opencode";
in
{
  home = {
    packages = [
      (config.lib.agents.mkSandbox {
        wrapperName = "ocd";
        package = pkgs.opencode;
        inherit agentDir;
      })
    ];
    activation = {
      opencodeConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] (
        hax.common.jsonUpdate pkgs "${config.xdg.configHome}/${agentDir}/opencode.json" [
          {
            prop = ".";
            text = lib.generators.toJSON { } settings;
          }
        ]
      );
    };
  };
}
