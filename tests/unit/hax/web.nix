{ pkgs, lib }:
let
  hax = import ../../../hax/web.nix { };

  # Helper to extract nginx config from module list
  getNginxVirtualHosts =
    modules:
    modules |> map (m: m.services.nginx.virtualHosts or { }) |> lib.foldl' lib.recursiveUpdate { };

  getAcmeCerts =
    modules: modules |> map (m: m.security.acme.certs or { }) |> lib.foldl' lib.recursiveUpdate { };

  getSystemdServices =
    modules: modules |> map (m: m.systemd.services or { }) |> lib.foldl' lib.recursiveUpdate { };
in
{
  # Test serve with root domain
  testServeRootDomain = {
    expr =
      let
        config = {
          domain = "example.com";
          root = "example.com";
          port = "3000";
          noRobots = false;
        };
        modules = hax.serve config;
        vhosts = getNginxVirtualHosts modules;
      in
      {
        hasMainDomain = vhosts ? "example.com";
        hasWwwRedirect = vhosts ? "www.example.com";
        mainDomainAcme = vhosts."example.com".enableACME or false;
        mainDomainSSL = vhosts."example.com".forceSSL or false;
        mainDomainDefault = vhosts."example.com".default or false;
        wwwRedirect = vhosts."www.example.com".globalRedirect or null;
        proxyPass = vhosts."example.com".locations."/".proxyPass or null;
      };
    expected = {
      hasMainDomain = true;
      hasWwwRedirect = true;
      mainDomainAcme = true;
      mainDomainSSL = true;
      mainDomainDefault = true;
      wwwRedirect = "example.com";
      proxyPass = "http://localhost:3000";
    };
  };

  # Test serve with subdomain (non-root)
  testServeSubdomain = {
    expr =
      let
        config = {
          domain = "api.example.com";
          root = "example.com";
          port = "8080";
          noRobots = false;
        };
        modules = hax.serve config;
        vhosts = getNginxVirtualHosts modules;
        certs = getAcmeCerts modules;
      in
      {
        hasSubdomain = vhosts ? "api.example.com";
        hasWwwRedirect = vhosts ? "www.api.example.com";
        subdomainUsesRootCert = vhosts."api.example.com".useACMEHost or null;
        subdomainSSL = vhosts."api.example.com".forceSSL or false;
        extraDomains = certs."example.com".extraDomainNames or [ ];
        proxyPass = vhosts."api.example.com".locations."/".proxyPass or null;
      };
    expected = {
      hasSubdomain = true;
      hasWwwRedirect = false; # No www redirect for subdomains
      subdomainUsesRootCert = "example.com";
      subdomainSSL = true;
      extraDomains = [ "api.example.com" ];
      proxyPass = "http://localhost:8080";
    };
  };

  # Test serve with noRobots
  testServeNoRobots = {
    expr =
      let
        config = {
          domain = "private.com";
          root = "private.com";
          port = "3000";
          noRobots = true;
        };
        modules = hax.serve config;
        vhosts = getNginxVirtualHosts modules;
      in
      {
        hasRobotsTxt = vhosts."private.com".locations ? "/robots.txt";
        robotsConfig = vhosts."private.com".locations."/robots.txt".extraConfig or null != null;
      };
    expected = {
      hasRobotsTxt = true;
      robotsConfig = true;
    };
  };

  # Test serveBinary
  testServeBinary = {
    expr =
      let
        config = {
          domain = "app.com";
          root = "app.com";
          port = "4000";
          noRobots = false;
          binary = "/usr/bin/myapp";
          cwd = "/var/lib/myapp";
        };
        modules = hax.serveBinary config;
        services = getSystemdServices modules;
        vhosts = getNginxVirtualHosts modules;
      in
      {
        hasSystemdService = services ? "app.com";
        execStart = services."app.com".serviceConfig.ExecStart or null;
        workingDir = services."app.com".serviceConfig.WorkingDirectory or null;
        envPort = services."app.com".serviceConfig.Environment or null;
        restart = services."app.com".serviceConfig.Restart or null;
        wantedBy = services."app.com".wantedBy or [ ];
        hasNginxProxy = vhosts ? "app.com";
      };
    expected = {
      hasSystemdService = true;
      execStart = "/usr/bin/myapp";
      workingDir = "/var/lib/myapp";
      envPort = "PORT=4000";
      restart = "always";
      wantedBy = [ "multi-user.target" ];
      hasNginxProxy = true;
    };
  };

  # Test complex scenario with subdomain and noRobots
  testComplexConfig = {
    expr =
      let
        config = {
          domain = "api.service.io";
          root = "service.io";
          port = "9000";
          noRobots = true;
          binary = "/opt/api/server";
          cwd = "/opt/api";
        };
        modules = hax.serveBinary config;
        vhosts = getNginxVirtualHosts modules;
        services = getSystemdServices modules;
        certs = getAcmeCerts modules;
      in
      {
        hasVhost = vhosts ? "api.service.io";
        hasNoWww = vhosts ? "www.api.service.io" == false;
        usesRootCert = vhosts."api.service.io".useACMEHost or null;
        hasRobots = vhosts."api.service.io".locations ? "/robots.txt";
        hasProxy = vhosts."api.service.io".locations."/".proxyPass or null == "http://localhost:9000";
        hasService = services ? "api.service.io";
        certExtraDomains = certs."service.io".extraDomainNames or [ ];
      };
    expected = {
      hasVhost = true;
      hasNoWww = true;
      usesRootCert = "service.io";
      hasRobots = true;
      hasProxy = true;
      hasService = true;
      certExtraDomains = [ "api.service.io" ];
    };
  };

  # Test serve minimal config
  testServeMinimal = {
    expr =
      let
        config = {
          domain = "min.test";
          root = "min.test";
          port = "1234";
          noRobots = false;
        };
        modules = hax.serve config;
        moduleCount = builtins.length modules;
      in
      {
        moduleCount = moduleCount; # Should have proxy, acme, www redirect
        hasExpectedModules = moduleCount == 4; # reverseProxy + acme (root) + wwwRedirect (2 modules)
      };
    expected = {
      moduleCount = 4;
      hasExpectedModules = true;
    };
  };
}
