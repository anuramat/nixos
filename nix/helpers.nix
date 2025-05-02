let
  acmeRoot = w: {
    services.nginx.virtualHosts.${w.domain} = {
      enableACME = true;
      forceSSL = true;
    };
  };
  acmeExtra = w: {
    services.nginx.virtualHosts.${w.domain} = {
      useACMEHost = w.root;
      forceSSL = true;
    };
    security.acme.certs.${w.root}.extraDomainNames = [ w.domain ];
  };
  reverseProxy = w: {
    services = {
      nginx = {
        virtualHosts.${w.domain} = {
          locations = {
            "/" = {
              proxyPass = "http://localhost:${w.port}";
            };
          };
        };
      };
    };
  };
  noRobots = w: {
  };
in
rec {
  serve =
    w:
    [ (reverseProxy w) ]
    ++ (if w ? root then [ (acmeExtra w) ] else [ (acmeRoot w) ])
    ++ (if w ? noRobots && w.noRobots == true then [ (noRobots w) ] else [ ]);
  serveBinary =
    w:
    (serve w)
    ++ [
      {
        systemd.services.${w.domain} = {
          after = [ "network.target" ];
          serviceConfig = {
            ExecStart = w.binary;
            Restart = "always";
            WorkingDirectory = w.cwd;
            Environment = "PORT=${w.port}";
          };
          wantedBy = [ "multi-user.target" ]; # why this
        };
      }
    ];
}
