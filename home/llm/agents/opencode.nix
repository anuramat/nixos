{
  pkgs,
  lib,
  config,
  ...
}:
let
  name = "opencode";
in
{
  home.packages = [
    (config.lib.agents.mkSandbox {
      inherit pkgs;
      pname = "ocd";
      agentName = name;
      cmd = "${lib.getExe pkgs.opencode}";
      extraRwDirs = [
        "$XDG_CONFIG_HOME/opencode"
        "$XDG_STATE_HOME/opencode"
        "$XDG_DATA_HOME/opencode"
        "$XDG_CACHE_HOME/opencode"
      ];
    })
  ];
}
