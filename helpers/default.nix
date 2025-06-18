{ lib, ... }@args:
rec {
  common = import ./common.nix args;
  web = import ./web.nix;
  root =
    let
      cacheFilename = "cache.pem.pub";
      clientKeyFiles =
        keyPath:
        with builtins;
        (
          readDir keyPath
          |> attrNames
          |> filter (x: hasSuffix ".pub" x && x != cacheFilename)
          |> map (x: keyPath + /${x})
        );
    in
    {

      allKeys = {

      };
      mkCluster =
        root: hostnames: name:
        with builtins;
        let
          allMachines = map mkMachine hostnames;
          otherMachines = filter (x: x.name != name) allMachines;
          inherit (lib.strings) hasSuffix;
          inherit (lib.lists) findFirst;

          mkMachine =
            name:
            with builtins;
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
              platform = config.nixpkgs.hostPlatform.system;
              cacheKey = readFile (keyPath + "/${cacheFilename}");
              hostKeysFile = keyPath + "/host_keys";
            };
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
          hostKeysFiles = otherMachines |> map (x: x.hostKeysFile);
          trusted-public-keys = otherMachines |> map (x: x.cacheKey) |> filter (x: x != null);
        };

    };
}
