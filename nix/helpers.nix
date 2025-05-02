{
  acmeRoot = domain: {
    services.nginx.virtualHosts.${domain}.enableACME = true;
    security.acme.certs.${domain}.extraDomainNames = [ "*.${domain}" ];
  };
  proxy = domain: port: {
    services = {
      nginx = {
        virtualHosts.${domain} = {
          forceSSL = true;
          locations = {
            "/" = {
              proxyPass = "http://localhost:${port}";
            };
          };
        };
      };
    };
  };
}
