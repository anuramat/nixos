let
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
            root = "${root}/static";
          };
          "/photos/" = {
            basicAuthFile = "${root}/.htpasswd";
            alias = "${root}/photos/";
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
