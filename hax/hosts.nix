{
  lib,
  consts,
  ...
}:
let

  inherit (consts) builderUsername cacheFilename cfgRoot;

  inherit (builtins)
    attrNames
    readDir
    filter
    readFile
    concatLists
    listToAttrs
    ;
  inherit (lib) nameValuePair;
in
rec {
  mkOthers =
    inputs: name:
    let
      names = attrNames inputs.self.nixosConfigurations;
      filterSelf = filter (v: v != name);
    in
    filterSelf names
    |> map (
      x:
      nameValuePair x (
        let
          cfg = inputs.self.nixosConfigurations.${x}.config;
        in
        {
          system = cfg.nixpkgs.hostPlatform.system;
          builder = cfg.users.users ? ${builderUsername};
        }
      )
    )
    |> listToAttrs;
  mkCacheKey = v: readFile (cfgRoot + "/${v}/keys/${cacheFilename}");
  mkClientKeyFiles =
    name:
    let
      keyDir = cfgRoot + "/${name}/keys";
      filenames = readDir keyDir |> attrNames;
      clientKeyFilenames = filter (x: lib.strings.hasSuffix ".pub" x && x != cacheFilename) filenames;
    in
    (map (x: keyDir + /${x}) clientKeyFilenames);
  mkKnownHostsFiles = names: map (v: cfgRoot + "/${v}/keys/host_keys") names;

  mkHostKeys =
    knownHostsFiles:
    map readFile knownHostsFiles
    |> map (v: v |> lib.splitString "\n")
    |> concatLists
    |> filter (v: v != "")
    |> map (v: v |> lib.splitString " " |> lib.drop 1 |> lib.concatStringsSep " ");
  mkKeyFiles = names: map mkClientKeyFiles names |> concatLists;
  mkSubstituters = builders: map (x: "ssh-ng://${x}?priority=50") builders;
  # lower number -- used earlier
  # cache.nixos.org has priority of 40, cachix -- 41
}
