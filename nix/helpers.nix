let
  acmeRoot = domain: {
    services.nginx.virtualHosts.${domain} = {
      enableACME = true;
      forceSSL = true;
    };
  };
  acmeExtra = root: domain: {
    services.nginx.virtualHosts.${domain} = {
      useACMEHost = root;
      forceSSL = true;
    };
    security.acme.certs.${root}.extraDomainNames = [ domain ];
  };
  reverseProxy = domain: port: {
    services = {
      nginx = {
        virtualHosts.${domain} = {
          locations = {
            "/" = {
              proxyPass = "http://localhost:${port}";
            };
          };
        };
      };
    };
  };
  noRobots = domain: {
    # TODO
  }
in
rec {
  serve =
    w:
    [ (reverseProxy w.domain w.port) ]
    ++ (if w ? root then [ (acmeExtra w.domain w.root) ] else [ (acmeRoot w.domain) ])
    ++ (if w ? noRobots && w.noRobots == true then [ (noRobots w.domain) ] else [ ]);
  serveBinary =
    b:
    serve b
    ++ [
      {
        systemd.services.${b.domain} = {
          after = [ "network.target" ];
          serviceConfig = {
            ExecStart = b.binary;
            Restart = "always";
            WorkingDirectory = b.cwd;
            Environment = "PORT=${b.port}";
          };
          wantedBy = [ "multi-user.target" ]; # why this
        };
      }
    ];
}
