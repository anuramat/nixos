{ pkgs, inputs, ... }:
let
  domain = "bin.ctrl.sn";
  email = "x@ctrl.sn";
  port = "8081";
in
{
  services = {
    nginx = {
      virtualHosts.${domain} = {
        forceSSL = true;
        enableACME = true;
        locations = {
          "/" = {
            proxyPass = "http://localhost:${port}";
          };
        };
      };
    };
  };

  security.acme = {
    certs."${domain}" = {
      inherit email;
    };
  };

  services.wastebin = { 
    enable = true;
    settings = {
      WASTEBIN_BASE_URL = "https://${domain}";
      WASTEBIN_ADDRESS_PORT = "localhost:${port}"
    };
  };

}
