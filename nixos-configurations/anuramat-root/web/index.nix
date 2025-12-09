{
  pkgs,
  lib,
  inputs,
  hax,
  ...
}:
lib.mkMerge (
  hax.web.serveBinary rec {
    noRobots = true;
    domain = "ctrl.sn";
    root = domain;
    cwd = "/var/www/";
    port = "8080";
    binary = "${inputs.ctrlsn.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/ctrl.sn";
  }
)
