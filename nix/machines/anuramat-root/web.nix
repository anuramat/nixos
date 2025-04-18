{ pkgs, inputs, ... }:
let
  domain = "ctrl.sn";
  email = "x@ctrl.sn";
  appName = "ctrl.sn";
  cwd = "/var/www/";
  port = "8080";
  binary = "${inputs.ctrlsn.packages.${pkgs.system}.default}/bin/ctrl.sn";
in
{
  systemd.services.${appName} = {
    after = [ "network.target" ];
    serviceConfig = {
      ExecStart = binary;
      Restart = "always";
      WorkingDirectory = cwd;
      Environment = "PORT=${port}";
    };
    wantedBy = [ "multi-user.target" ]; # why this
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
  services = {
    nginx = {
      enable = true;
      recommendedProxySettings = true;
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
    acceptTerms = true;
    certs."${domain}" = {
      inherit email;
    };
  };
}
