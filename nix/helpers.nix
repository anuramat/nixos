{
  acmeRoot = domain: {
    services.nginx.virtualHosts.${domain}.enableACME = true;
  };
  acmeExtra = domain: extra: {
    services.nginx.virtualHosts.${extra}.useACMEHost = domain;
    security.acme.certs.${domain}.extraDomainNames = [ extra ];
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
