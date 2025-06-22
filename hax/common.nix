# TODO rename file
{ lib, ... }:
with lib;
with builtins;
rec {
  readLines = v: v |> readFile |> splitString "\n" |> filter (x: x != "");
  getSchema = attrsets.mapAttrsRecursive (path: v: typeOf (v));
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
  gitHook =
    pkgs: main:
    pkgs.writeShellScript "hook" # bash
      ''
        hook_name=$(basename "$0")
        local=./.git/hooks/$hook_name
        [ -x "$local" ] && [ -f "$local" ] && {
        	exec "$local"
        }
      ''
    + main;
}
