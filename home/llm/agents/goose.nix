{
  pkgs,
  hax,
  lib,
  ...
}:
let
  name = "Goose";
in
{
  home.packages = [
    (hax.agents.mkSandbox {
      inherit pkgs;
      pname = "gse";
      agentName = name;
      cmd = "${lib.getExe pkgs.goose}";
      extraRwDirs = [
        "$XDG_CONFIG_HOME/goose"
        "$XDG_STATE_HOME/goose"
      ];
    })
  ];
}
