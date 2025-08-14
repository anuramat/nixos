args:
let
  inherit (builtins)
    attrNames
    readDir
    filter
    readFile
    concatLists
    ;
  inherit (args.lib)
    nameValuePair
    listToAttrs
    removeSuffix
    hasSuffix
    ;
in
readDir ./.
|> attrNames
|> filter (x: x != "default.nix" && hasSuffix ".nix" x) # nix files except default.nix
|> map (x: nameValuePair (removeSuffix ".nix" x) (import (./. + "/${x}") args))
|> listToAttrs
