# TODO move
{
  lib,
  inputs,
  hax,
  user,
  config,
  ...
}:
let
  root = ./. + "/nixos-configurations/";
  hostname = config.networking.hostName;
  inherit (builtins)
    attrNames
    readDir
    filter
    readFile
    concatLists
    ;
  others =
    let
      hostnames = attrNames inputs.self.nixosConfigurations;
      filterSelf = filter (v: v != hostname);
    in
    filterSelf hostnames;
  builders =
    let
      isBuilder = v: inputs.self.nixosConfigurations.${v}.config.users.users ? ${builderUsername};
    in
    lib.filter isBuilder others;
  hostnameToCacheKey = v: readFile (root + "/${v}/keys/${cacheFilename}");
  cacheFilename = "cache.pem.pub";
  hostnameToClientKeyFiles =
    v:
    let
      keyDir = root + "/${v}/keys";
      filenames = readDir keyDir |> attrNames;
      clientKeyFilenames = filter (x: lib.strings.hasSuffix ".pub" x && x != cacheFilename) filenames;
    in
    (map (x: keyDir + /${x}) clientKeyFilenames);
  knownHostsFiles = others |> map (v: root + "/${v}/keys/host_keys");

  hostKeys =
    knownHostsFiles
    |> map readFile
    |> map (v: v |> lib.splitString "\n")
    |> concatLists
    |> filter (v: v != "")
    |> map (v: v |> lib.splitString " " |> lib.drop 1 |> lib.concatStringsSep " ");
  keyFiles = others |> map hostnameToClientKeyFiles |> concatLists;
  substituters = map (x: "ssh-ng://${x}?priority=50") builders;
  # lower number -- used earlier
  # cache.nixos.org has priority of 40, cachix -- 41
  trusted-public-keys = map hostnameToCacheKey builders;
  builderUsername = "builder";
in
{
  lib.hosts = {
    inherit
      builderUsername
      substituters # binary cache
      keyFiles # ssh public keys
      knownHostsFiles # agenix(?)/ssh host auth
      trusted-public-keys # packages signature
      builders
      ;
    hostnames = others;
  };
}
