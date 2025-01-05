# XXX remember to update the machine_template.sh
{
  lib,
  u,
  inputs,
}:
with builtins;
let
  inherit (lib.strings) hasSuffix;
  hostnames = u.epsilon ./.;
  mkMachine =
    name:
    let
      config = inputs.self.nixosConfigurations.${name}.config;
      cacheFilename = "cache.pem.pub";
      cachePath = path + "/${cacheFilename}";
      path = ./${name}/keys;
      builder = !config.nix.distributedBuilds;
    in
    rec {
      inherit name builder;
      platform = config.nixpkgs.hostPlatform.system;
      cacheKey = if builder then readFile cachePath else null;
      clientKeyFiles = (
        readDir path
        |> attrNames
        |> filter (x: hasSuffix ".pub" x && x != cacheFilename)
        |> map (x: path + /${x})
      );
      hostKeysFile = path + "/host_keys";
      module = ./${name};
    };
in
{
  inherit hostnames;
  mkMachines =
    name:
    (
      let
        machines = hostnames |> map mkMachine;
        others = filter (x: x.name != name) machines;
      in
      rec {
        builders = filter (x: x.builder) others;
        this = (mkMachine name);
        clientKeyFiles = others |> map (x: x.clientKeyFiles) |> concatLists;
        substituters = builders |> map (x: "ssh-ng://${x.name}");
        trusted-public-keys = builders |> map (x: x.cacheKey) |> filter (x: x != null);
        builderUsername = "builder";
        hostKeysFiles = others |> map (x: x.hostKeysFile);
      }
    );
}
