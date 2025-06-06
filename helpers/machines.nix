{ machinesPath, inputs }:
with builtins;
let
  lib = inputs.nixpkgs.lib;
  inherit (lib.strings) hasSuffix;
  inherit (lib.lists) findFirst;

  hostnames =
    machinesPath |> builtins.readDir |> builtins.attrNames |> builtins.filter (a: a != "default.nix");
  mkMachine =
    name:
    let
      inherit (inputs.self.nixosConfigurations.${name}) config;
      cacheFilename = "cache.pem.pub";
      keysPath = machinesPath + /${name}/keys;
    in
    rec {
      inherit name;
      builder = !config.nix.distributedBuilds;
      server = config.machine.remote;
      desktop = !server;
      platform = config.nixpkgs.hostPlatform.system;
      cacheKey = if builder then readFile (keysPath + "/${cacheFilename}") else null;
      clientKeyFiles = (
        readDir keysPath
        |> attrNames
        |> filter (x: hasSuffix ".pub" x && x != cacheFilename)
        |> map (x: keysPath + /${x})
      );
      hostKeysFile = keysPath + "/host_keys";
    };
in
{
  inherit hostnames;

  mkModules = name: [
    (machinesPath + /${name})
    (_: {
      networking.hostName = name;
    })
  ];

  mkCluster =
    name:
    let
      allMachines = map mkMachine hostnames;
      otherMachines = filter (x: x.name != name) allMachines;
    in
    rec {
      this = findFirst (x: x.name == name) null allMachines;
      inherit hostnames;

      builderUsername = "builder";
      builders = filter (x: x.builder) otherMachines;
      substituters = builders |> map (x: "ssh-ng://${x.name}?priority=50");
      # lower number -- used earlier
      # cache.nixos.org has priority of 40, cachix -- 41

      clientKeyFiles = otherMachines |> map (x: x.clientKeyFiles) |> concatLists;
      miscKeys = [
        # TODO move the keys to a file or a folder
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKl0YHcx+ju+3rsPerkAXoo2zI4FXRHaxzfq8mNHCiSD anuramat-iphone16"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINBre248H/l0+aS5MJ+nr99m10g44y+UsaKTruszS6+D anuramat-ipad"
      ];
      hostKeysFiles = otherMachines |> map (x: x.hostKeysFile);
      trusted-public-keys = builders |> map (x: x.cacheKey) |> filter (x: x != null);
    };
}
