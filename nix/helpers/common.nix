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
}
