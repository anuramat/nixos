args:
let
  inherit (builtins)
    attrNames
    readDir
    filter
    readFile
    concatLists
    ;
  inherit (args.lib) nameValuePair listToAttrs removeSuffix;
in
readDir ./.
|> attrNames
|> filter (x: x != "default.nix") # filenames except default.nix
|> map (x: nameValuePair (removeSuffix ".nix" x) (import (./. + "/${x}") args))
|> listToAttrs
