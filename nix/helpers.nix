{
  acmeRoot = domain: {
    services.nginx.virtualHosts.${domain}.enableACME = true;
  };
  acmeExtra = domain: extra: {
    services.nginx.virtualHosts.${domain}.useACMEHost = domain;
    security.acme.certs.${extra}.extraDomainNames = [ extra ];
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
