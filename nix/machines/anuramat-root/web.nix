{ config, ... }:
let
  # home = config.users.users.${config.user}.home;
  # root = "${home}/public";
  root = "/var/www";
  domain = "ctrl.sn";
  email = "x@ctrl.sn";
in
{
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
  services = {
    nginx = {
      enable = true;
      virtualHosts.${domain} = {
        forceSSL = true;
        enableACME = true;
        locations = {
          "/" = {
            inherit root;
            extraConfig = ''
              autoindex on;
            '';
          };
        };
      };
    };
  };

  security.acme = {
    acceptTerms = true;
    certs."${domain}" = {
      inherit email;
    };
  };
}
