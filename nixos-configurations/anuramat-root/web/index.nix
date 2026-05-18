{
  pkgs,
  inputs,
  ...
}:
{
  web.sites = [
    {
      noRobots = true;
      domain = "ctrl.sn";
      root = "ctrl.sn";
      cwd = "/var/www/";
      port = "8080";
      binary = "${inputs.ctrlsn.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/ctrl.sn";
    }
  ];
}
