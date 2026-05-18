{ config, lib, ... }:
let
  inherit (lib)
    mkOption
    types
    mkMerge
    optional
    concatMap
    ;
  siteType = types.submodule {
    options = {
      root = mkOption { type = types.str; };
      domain = mkOption { type = types.str; };
      port = mkOption { type = types.str; };
      noRobots = mkOption {
        type = types.bool;
        default = true;
      };
      binary = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      cwd = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
    };
  };
  vhostsFor =
    w:
    [
      { ${w.domain}.locations."/".proxyPass = "http://localhost:${w.port}"; }
      (
        if w.root == w.domain then
          {
            ${w.domain} = {
              enableACME = true;
              forceSSL = true;
              default = true;
            };
          }
        else
          {
            ${w.domain} = {
              useACMEHost = w.root;
              forceSSL = true;
            };
          }
      )
    ]
    ++ optional w.noRobots {
      ${w.domain}.locations."/robots.txt".extraConfig = # nginx
        ''
          return 200 "User-agent: *\nDisallow: /";
        '';
    }
    ++ optional (w.root == w.domain) {
      "www.${w.domain}" = {
        globalRedirect = w.domain;
        useACMEHost = w.root;
        forceSSL = true;
      };
    };
  acmeCertsFor =
    w:
    optional (w.root != w.domain) {
      ${w.root}.extraDomainNames = [ w.domain ];
    }
    ++ optional (w.root == w.domain) {
      ${w.root}.extraDomainNames = [ "www.${w.domain}" ];
    };
  systemdServicesFor =
    w:
    optional (w.binary != null) {
      ${w.domain} = {
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          ExecStart = w.binary;
          Restart = "always";
          WorkingDirectory = w.cwd;
          Environment = "PORT=${w.port}";
        };
      };
    };
in
{
  options.web.sites = mkOption {
    type = types.listOf siteType;
    default = [ ];
  };
  config = {
    services.nginx.virtualHosts = mkMerge (concatMap vhostsFor config.web.sites);
    security.acme.certs = mkMerge (concatMap acmeCertsFor config.web.sites);
    systemd.services = mkMerge (concatMap systemdServicesFor config.web.sites);
  };
}
