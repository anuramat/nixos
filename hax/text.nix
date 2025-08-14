{ lib, ... }:
let
  inherit (lib) trim splitString concatStringsSep filterAttrs mapAttrsToList;
in
rec {
  fmt = x: x |> trim |> splitString "\n";
  
  prependFrontmatter = text: fields:
    let
      fm = fields
        |> filterAttrs (n: v: v != null)
        |> mapAttrsToList (n: v: n + ": " + v)
        |> lib.sort (a: b: a < b)
        |> concatStringsSep "\n";
    in
    [ "---" fm "---" text ] |> concatStringsSep "\n";
  
  mkGlob = globExp: "--glob=!${globExp}";
}