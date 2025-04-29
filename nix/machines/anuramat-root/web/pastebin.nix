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
}
