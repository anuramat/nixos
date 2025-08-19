# TODO rename file
{ lib, ... }:
with lib;
with builtins;
rec {
  readLines = v: v |> readFile |> splitString "\n" |> filter (x: x != "");
  getSchema = attrsets.mapAttrsRecursive (path: v: typeOf v);
  join = s: with lib; s |> splitString "\n" |> concatStringsSep " ";
  getMatches =
    patterns: x:
    mapAttrs (
      name: schema: if typeOf x == "set" then schema == getSchema x else schema == typeOf x
    ) patterns;
  # TODO maybe move
  pythonConfig =
    root: cfg:
    let
      formatValue =
        v:
        if builtins.isBool v then
          (if v then "True" else "False")
        else if builtins.isString v then
          ''"${v}"''
        else
          toString v;
      formatAssignment =
        prefix: name: value:
        if builtins.isAttrs value then
          lib.concatStringsSep "\n" (lib.mapAttrsToList (formatAssignment "${prefix}.${name}") value)
        else
          "${prefix}.${name} = ${formatValue value}";
    in
    lib.concatStringsSep "\n" (lib.mapAttrsToList (formatAssignment root) cfg);
  mkDirSet =
    func: dir:
    with builtins;
    readDir dir
    |> attrNames
    |> map (n: lib.nameValuePair (lib.removeSuffix ".nix" n) (func /${dir}/${n})) # assert .nix equiv regular; assert no collisions
    |> lib.listToAttrs;
  mkImportSet = mkDirSet (x: import x);
}
