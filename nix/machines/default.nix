# XXX remember to update the machine_template.sh
{
  lib,
  u,
}:
with builtins;
let
  inherit (lib.strings) hasSuffix;
  mkMachine =
    name:
    let
      cacheFilename = "cache.pem.pub";
      cachePath = path + "/${cacheFilename}";
      path = ./${name}/keys;
      meta = import ./${name}/meta.nix;
    in
    rec {
      inherit name;
      # stuff that is REQUIRED on every (builder) system
      # OR interconnectivity configuration, where you need to reference other systems
      # machine specific configs go to machine modules
      # TODO
      # maybe builder can just be the distributed builds var
      # but where would the keyboard go... I'll still need some sort of a
      # per-machine file that would be validated by some other script
      inherit (meta) builder keyboard;
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
  hostnames = u.epsilon ./.;
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
