{
  pkgs,
  lib,
  inputs,
  helpers,
  ...
}:
{
  config = lib.mkMerge (
    helpers.serveBinary {
      noRobots = true;
      domain = "ctrl.sn";
      cwd = "/var/www/";
      port = "8080";
      binary = "${inputs.ctrlsn.packages.${pkgs.system}.default}/bin/ctrl.sn";
    }
  );
}
