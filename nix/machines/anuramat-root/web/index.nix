{
  pkgs,
  lib,
  inputs,
  helpers,
  ...
}:
lib.mkMerge (
  helpers.serveBinary rec {
    noRobots = true;
    domain = "ctrl.sn";
    root = domain;
    cwd = "/var/www/";
    port = "8080";
    binary = "${inputs.ctrlsn.packages.${pkgs.system}.default}/bin/ctrl.sn";
  }
)
