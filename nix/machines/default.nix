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
  hostnames = u.epsilon ./.;
in
{
  inherit hostnames;
  machines =
    name:
    (
      let
        getMachine =
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
        machines = hostnames |> map getMachine;
        others = filter (x: x.name != name) machines;
        builders = filter (x: x.builder) others;
        this = (getMachine name);
      in
      {
        inherit builders this hostnames;
        clientKeyFiles = others |> map (x: x.clientKeyFiles) |> concatLists;
        substituters = builders |> map (x: "ssh-ng://${x.hostname}");
        trusted-public-keys = builders |> map (x: x.cacheKey) |> filter (x: x != null);
        builderUsername = "builder";
        hostKeysFiles = others |> map (x: x.hostKeysFile);
      }
    );
}
