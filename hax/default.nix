args:
with args.lib;
builtins.readDir ./.
|> attrNames
|> filter (x: x != "default.nix" && hasSuffix ".nix" x) # nix files except default.nix
|> map (x: nameValuePair (removeSuffix ".nix" x) (import (./. + "/${x}") args))
|> listToAttrs
