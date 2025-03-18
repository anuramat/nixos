{ config, ... }:
let
  home = config.users.users.${config.user}.home;
in
{
  # web {{{1
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
  services.static-web-server = {
    enable = true;
    listen = "[::]:80";
    root = "${home}/public";
    configuration = {
      general = {
        directory-listing = true;
      };
    };
  };
  services.certbot = {
    enable = true;
    agreeTerms = true;
  };
}
