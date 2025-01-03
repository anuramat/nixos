{
  lib,
  u,
}:
let
  inherit (builtins)
    filter
    concatLists
    readDir
    attrNames
    pathExists
    readFile
    ;
  inherit (lib.strings) hasSuffix;

  mkMachine =
    name:
    let
      cacheFilename = "cache.pem.pub";
      cachePath = path + "/${cacheFilename}";
      path = ./${name}/keys;
      meta = import ./${name}/meta.nix;
    in
    {
      inherit name;
      inherit (meta) builder platform;
      cacheKey = if pathExists cachePath then readFile cachePath else null;
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
rec {
  hostnames = u.epsilon ./.;
  machines =
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
