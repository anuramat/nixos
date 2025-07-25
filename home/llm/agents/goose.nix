{
  pkgs,
  lib,
  config,
  ...
}:
let
  name = "goose";
in
{
  home.packages = [
    (config.lib.agents.mkSandbox {
      inherit pkgs;
      pname = "goose-sandboxed";
      agentName = name;
      cmd = "${lib.getExe pkgs.goose}";
      xdgSubdir = "goose";
      extraRwDirs = [
        "$XDG_CONFIG_HOME/goose"
        "$XDG_STATE_HOME/goose"
      ];
    })
  ];
}
