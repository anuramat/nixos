{ inputs, epsilon }:
with builtins;
let
  inherit (inputs.nixpkgs.lib.strings) hasSuffix;

  hostnames = epsilon ./.;
  mkMachine =
    name:
    let
      inherit (inputs.self.nixosConfigurations.${name}) config;
      cacheFilename = "cache.pem.pub";
      path = ./${name}/keys;
    in
    rec {
      inherit name;
      builder = !config.nix.distributedBuilds;
      platform = config.nixpkgs.hostPlatform.system;
      cacheKey = if builder then readFile (path + "/${cacheFilename}") else null;
      clientKeyFiles = (
        readDir path
        |> attrNames
        |> filter (x: hasSuffix ".pub" x && x != cacheFilename)
        |> map (x: path + /${x})
      );
      hostKeysFile = path + "/host_keys";
    };
in
{
  inherit hostnames;

  mkModules = name: [
    ./${name}
    (_: {
      networking.hostName = name;
    })
  ];

  mkCluster =
    name:
    let
      machines = hostnames |> map mkMachine |> filter (x: x.name != name);
    in
    rec {
      builders = filter (x: x.builder) machines;

      substituters = builders |> map (x: "ssh-ng://${x.name}");

      builderUsername = "builder";
      clientKeyFiles = machines |> map (x: x.clientKeyFiles) |> concatLists;
      # TODO move the keys to a file or a folder
      miscKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKl0YHcx+ju+3rsPerkAXoo2zI4FXRHaxzfq8mNHCiSD anuramat-iphone16"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINBre248H/l0+aS5MJ+nr99m10g44y+UsaKTruszS6+D anuramat-ipad"
      ];
      hostKeysFiles = machines |> map (x: x.hostKeysFile);
      trusted-public-keys = builders |> map (x: x.cacheKey) |> filter (x: x != null);
    };
}
