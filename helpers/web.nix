let
  acme =
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
    in
    w: if w.root == w.domain then (acmeRoot w) else (acmeExtra w);
  wwwRedirect =
    let
      redirect =
        from: w:
        let
          rw = {
            root = w.root;
            domain = from;
          };
        in
        [
          {
            services.nginx.virtualHosts.${from} = {
              globalRedirect = w.domain;
            };
          }
        ]
        ++ (acme rw);
    in
    w: (redirect ("www." + w.domain) w);
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
  noRobots = w: [
    {
      services.nginx.virtualHosts.${w.domain}.locations."/robots.txt" = {
        extraConfig = # nginx
          ''
            return 200 "User-agent: *\nDisallow: /";
          '';
      };
    }
  ];
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
  serve =
    w:
    (reverseProxy w)
    ++ (acme w)
    ++ (if w.noRobots then noRobots w else [ ])
    ++ (if w.root == w.domain then wwwRedirect w else [ ]);
  serveBinary = w: (serve w) ++ (binaryService w);
}
