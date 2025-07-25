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
      pname = "opencode-sandboxed";
      agentName = name;
      cmd = "${lib.getExe pkgs.opencode}";
      xdgSubdir = "opencode";
      extraRwDirs = [
      ];
    })
  ];
}
