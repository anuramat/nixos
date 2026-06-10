# TODO move
{
  config,
  inputs,
  lib,
  ...
}:
{
  lib.hosts =
    let
      inherit (inputs.self.consts) builderUsername;
      inherit (lib) filterAttrs attrNames concatMap;

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
    in
    {
      substituters = mkSubstituters builderNames; # binary cache
      keyFiles = names |> concatMap (h: inputs.self.keys.${h}.clientKeyFiles); # ssh public keys
      knownHostsFiles = names |> map (h: inputs.self.keys.${h}.knownHostsFile); # agenix(?)/ssh host auth
      trusted-public-keys = names |> map (h: inputs.self.keys.${h}.cacheKey); # packages signature
      inherit hosts builders;
    };
}
