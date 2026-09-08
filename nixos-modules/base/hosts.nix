# TODO move
{
  config,
  inputs,
  lib,
  ...
}:
let
  inherit (inputs.self) keys;
  registry = inputs.self.hosts;
  builderUsername = "builder";

  name = config.networking.hostName;
  hosts = lib.filterAttrs (n: _: n != name) registry;
  names = lib.attrNames hosts;
  builders = lib.filterAttrs (n: v: v.builder) hosts;
  cachePort = 5000;

  # lower priority number -> used earlier; cache.nixos.org=40, cachix=41
  mkSubstituters = map (x: "http://${x}:${toString cachePort}?priority=50");
in
{
  assertions = [
    {
      assertion = lib.attrNames registry == lib.attrNames inputs.self.nixosConfigurations;
      message = "flake output `hosts` is out of sync with nixos-configurations/";
    }
    {
      assertion =
        registry ? ${name}
        && registry.${name}.system == config.nixpkgs.hostPlatform.system
        && registry.${name}.builder == (config.users.users ? ${builderUsername});
      message = "flake output `hosts.${name}` is missing or stale";
    }
  ];

  lib.hosts = {
    substituters = mkSubstituters (lib.attrNames builders);
    trusted-substituters = mkSubstituters names;
    keyFiles = names |> lib.concatMap (h: keys.${h}.clientKeyFiles); # ssh public keys
    knownHostsFiles = names |> map (h: keys.${h}.knownHostsFile); # agenix(?)/ssh host auth
    trusted-public-keys = names |> map (h: keys.${h}.cacheKey); # packages signature
    inherit
      builders
      builderUsername
      cachePort
      ;
  };
}
