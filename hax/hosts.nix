{ lib, ... }@args:
let
  cacheFilename = "cache.pem.pub";
  getClientKeyFiles =
    keyPath:
    (
      builtins.readDir keyPath
      |> builtins.attrNames
      |> builtins.filter (x: lib.strings.hasSuffix ".pub" x && x != cacheFilename)
      |> builtins.map (x: keyPath + /${x})
    );

  # TODO deduplicate keypath
  getHostnames =
    with builtins;
    path: path |> readDir |> attrNames |> filter (a: a != "external_keys.nix");
in
{
  inherit getHostnames;
  getAllHostkeys =
    path:
    with builtins;
    getHostnames path
    |> map (v: path + "/${v}/keys/host_keys")
    |> map readFile
    |> map (lib.splitString "\n")
    |> concatLists
    |> filter (x: x != "");
  getAllKeys =
    path:
    getHostnames path |> map (v: path + "/${v}/keys") |> map getClientKeyFiles |> builtins.concatLists;
  mkCluster =
    root: hostnames: name:
    let
      allMachines = map mkMachine hostnames;
      otherMachines = builtins.filter (x: x.name != name) allMachines;
      mkMachine =
        name:
        let
          inherit (args.inputs.self.nixosConfigurations.${name}) config;
          path = root + "/${name}";
          meta = import (path + "/meta.nix");
          keyPath = path + "/keys";
        in
        rec {
          inherit name;
          builder = !config.nix.distributedBuilds;
          server = meta.server;
          desktop = !server;
          clientKeyFiles = getClientKeyFiles keyPath;
          platform = config.nixpkgs.hostPlatform.system;
          cacheKey = builtins.readFile (keyPath + "/${cacheFilename}");
          hostKeysFile = keyPath + "/host_keys";
        };
    in
    rec {
      this = lib.lists.findFirst (x: x.name == name) null allMachines;
      inherit hostnames;

      builderUsername = "builder";
      builders = builtins.filter (x: x.builder) otherMachines;
      substituters = builders |> map (x: "ssh-ng://${x.name}?priority=50");
      # lower number -- used earlier
      # cache.nixos.org has priority of 40, cachix -- 41

      clientKeyFiles = otherMachines |> map (x: x.clientKeyFiles) |> builtins.concatLists;
      hostKeysFiles = otherMachines |> map (x: x.hostKeysFile);
      trusted-public-keys = otherMachines |> map (x: x.cacheKey) |> builtins.filter (x: x != null);
    };

}
