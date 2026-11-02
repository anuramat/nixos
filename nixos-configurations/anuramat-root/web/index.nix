{
  config,
  lib,
  pkgs,
  ...
}:
let
  domain = "ctrl.sn";
  port = "8080";
in
{
  web.sites = [
    {
      inherit domain port;
      root = domain;
    }
  ];
  systemd.services.${domain} = {
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    environment = {
      PORT = port;
      # uploaded by hand, must be world-readable
      PHOTO_DIR = "/var/www/photo";
    };
    serviceConfig = {
      ExecStart = lib.getExe pkgs.ctrlsn;
      # PHOTO_PASS=...
      EnvironmentFile = config.age.secrets.ctrlsn.path;
      DynamicUser = true;
      Restart = "always";
    };
  };
}
