{ lib, config, ... }:
let
  home = config.users.users.${config.user}.home;
  root = "${home}/public";
  domain = "ctrl.sn";
in
{
  # web {{{1
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
  services.static-web-server = {
    enable = true;
    listen = "[::]:443";
    configuration = {
      general = {
        directory-listing = true;
        http2 = true;
        http2-tls-cert = "/var/lib/acme/${domain}/fullchain.pem";
        http2-tls-key = "/var/lib/acme/${domain}/key.pem";
      };
    };
  };

  security.acme = {
    acceptTerms = true;
    certs."${domain}" = {
      reloadServices = [ "static-web-server" ];
      listenHTTP = ":80";
      group = "www-data";
    };
  };
  users.groups.www-data = { };

  # TODO wtf is this paragraph for
  systemd.services.static-web-server.serviceConfig.SupplementaryGroups = lib.mkForce [
    ""
    "www-data"
  ];
  systemd.services.static-web-server.serviceConfig.BindReadOnlyPaths = lib.mkForce [
    root
    "/var/lib/acme/${domain}"
  ];

}
