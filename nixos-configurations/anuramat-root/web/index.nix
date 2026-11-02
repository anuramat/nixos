{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  domain = "ctrl.sn";
  port = "8080";
  inherit (inputs.self.consts.user) username;
in
{
  web.sites = [
    {
      inherit domain port;
      root = domain;
    }
  ];
  # photos are uploaded by hand, then `make` in /var/www generates previews;
  # world-readable, since the service runs as a dynamic user
  systemd.tmpfiles.rules = [
    "d /var/www/photo/fullsize 0755 ${username} users -"
    "d /var/www/photo/preview 0755 ${username} users -"
    "L+ /var/www/Makefile - - - - ${
      pkgs.replaceVars ./previews.mk {
        fd = lib.getExe pkgs.fd;
        magick = lib.getExe' pkgs.imagemagick "magick";
      }
    }"
  ];
  systemd.services.${domain} = {
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    environment = {
      PORT = port;
      PHOTO_DIR = "/var/www/photo";
    };
    serviceConfig = {
      ExecStart = lib.getExe (
        import ./ctrlsn {
          inherit pkgs;
          inherit (inputs) crane fslightbox modern-normalize;
        }
      );
      # PHOTO_PASS=...
      EnvironmentFile = config.age.secrets.ctrlsn.path;
      DynamicUser = true;
      Restart = "always";
    };
  };
}
