let
  acmeRoot = w: [
    {
      services.nginx.virtualHosts.${w.domain} = {
        enableACME = true;
        forceSSL = true;
        default = true;
      };
    }
  ];
  acmeExtra = w: [
    {
      services.nginx.virtualHosts.${w.domain} = {
        useACMEHost = w.root;
        forceSSL = true;
      };
      security.acme.certs.${w.root}.extraDomainNames = [ w.domain ];
    }
  ];
  reverseProxy = w: [
    {
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
    }
  ];
  robots =
    w:
    if w.noRobots then
      [
        {
          services.nginx.virtualHosts.${w.domain}.locations."/robots.txt" = {
            extraConfig = ''
              return 200 "User-agent: *\nDisallow: /";
            '';
          };
        }
      ]
    else
      [ ];
  binaryService = w: [
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
in
rec {
  acme = w: (if w.root == null then (acmeRoot w) else (acmeExtra w));
  serve = w: (reverseProxy w) ++ (acme w) ++ (robots w);
  serveBinary = w: (serve w) ++ (binaryService w)
}
