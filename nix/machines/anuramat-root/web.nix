let
  root = "/var/www/static";
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
              autoindex_exact_size off;
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
