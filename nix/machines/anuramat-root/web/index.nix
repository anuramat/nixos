{
  pkgs,
  lib,
  inputs,
  helpers,
  ...
}:
lib.mkMerge (
  helpers.serveBinary {
    root = null;
    noRobots = true;
    domain = "ctrl.sn";
    cwd = "/var/www/";
    port = "8080";
    binary = "${inputs.ctrlsn.packages.${pkgs.system}.default}/bin/ctrl.sn";
  }
)
