{
  pkgs,
  lib,
  config,
  ...
}:
let
  name = "amp";
in
{
  home.packages = [
    (config.lib.agents.mkSandbox {
      inherit pkgs;
      pname = "amp-sandboxed";
      agentName = name;
      cmd = "${lib.getExe pkgs.amp}";
      xdgSubdir = "amp";
      extraRwDirs = [
        "$HOME/.amp"
      ];
    })
  ];
}
