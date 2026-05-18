# TODO move
{
  hax,
  config,
  inputs,
  lib,
  ...
}:
{
  lib.hosts =
    let
      inherit (inputs.self.consts) builderUsername cacheFilename cfgRoot;
      inherit (lib) filterAttrs attrNames;
      inherit (builtins) readFile map;

      name = config.networking.hostName;

      mkOthers =
        let
          cfgs = inputs.self.nixosConfigurations;
          allNames = attrNames cfgs |> map (x: cfgs.${x}.config.networking.hostName);
        in
        allNames
        |> lib.filter (v: v != name)
        |> map (
          x:
          lib.nameValuePair x (
            let
              cfg = inputs.self.nixosConfigurations.${x}.config;
            in
            {
              system = cfg.nixpkgs.hostPlatform.system;
              builder = cfg.users.users ? ${builderUsername};
            }
          )
        )
        |> lib.listToAttrs;

      hosts = mkOthers;
      names = attrNames hosts;
      builders = filterAttrs (n: v: v.builder) hosts;
      builderNames = attrNames builders;

      # lower priority number -> used earlier; cache.nixos.org=40, cachix=41
      mkSubstituters = map (x: "ssh-ng://${x}?priority=50");
      mkKnownHostsFiles = map (v: cfgRoot + "/${v}/keys/host_keys");
      mkCacheKey = v: readFile (cfgRoot + "/${v}/keys/${cacheFilename}");
    in
    {
      substituters = mkSubstituters builderNames; # binary cache
      keyFiles = hax.hosts.mkKeyFiles names; # ssh public keys
      knownHostsFiles = mkKnownHostsFiles names; # agenix(?)/ssh host auth
      trusted-public-keys = map mkCacheKey names; # packages signature
      inherit hosts builders;
    };
}
