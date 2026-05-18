# TODO rename helpers
{
  lib,
  inputs,
  ...
}:
let
  inherit (inputs.self.consts) cacheFilename cfgRoot;

  inherit (builtins)
    attrNames
    readDir
    filter
    readFile
    concatLists
    ;
in
rec {
  mkClientKeyFiles =
    name:
    let
      keyDir = cfgRoot + "/${name}/keys";
      filenames = readDir keyDir |> attrNames;
      clientKeyFilenames = filter (x: lib.strings.hasSuffix ".pub" x && x != cacheFilename) filenames;
    in
    map (x: keyDir + /${x}) clientKeyFilenames;
  mkKeyFiles = names: map mkClientKeyFiles names |> concatLists;
  mkHostKeys =
    names:
    map (v: cfgRoot + "/${v}/keys/host_keys") names
    |> map readFile
    |> map (v: v |> lib.splitString "\n")
    |> concatLists
    |> filter (v: v != "")
    |> map (v: v |> lib.splitString " " |> lib.drop 1 |> lib.concatStringsSep " ");
}
