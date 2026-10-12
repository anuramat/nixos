{ lib, pkgs, ... }:
{
  web.sites = [
    {
      domain = "ctrl.sn";
      root = "ctrl.sn";
      cwd = "/var/www/";
      port = "8080";
      binary = lib.getExe pkgs.ctrlsn;
    }
  ];
}
