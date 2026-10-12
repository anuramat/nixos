{
  config,
  inputs,
  lib,
  ...
}:
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
    let
      isRoot = w.root == w.domain;
    in
    [
      {
        ${w.domain} = {
          locations."/".proxyPass = "http://localhost:${w.port}";
          forceSSL = true;
          enableACME = isRoot;
          default = isRoot;
          useACMEHost = if isRoot then null else w.root;
        };
      }
    ]
    ++ optional w.noRobots {
      ${w.domain}.locations."/robots.txt".extraConfig = # nginx
        ''
          return 200 "User-agent: *\nDisallow: /";
        '';
    }
    ++ optional isRoot {
      "www.${w.domain}" = {
        globalRedirect = w.domain;
        useACMEHost = w.root;
        forceSSL = true;
      };
    };
  acmeCertFor = w: {
    ${w.root}.extraDomainNames = [ (if w.root == w.domain then "www.${w.domain}" else w.domain) ];
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
    users.users.${inputs.self.consts.user.username}.extraGroups =
      optional config.services.nginx.enable "nginx";
    services.nginx.virtualHosts = mkMerge (concatMap vhostsFor config.web.sites);
    security.acme.certs = mkMerge (map acmeCertFor config.web.sites);
    systemd.services = mkMerge (concatMap systemdServicesFor config.web.sites);
  };
}
