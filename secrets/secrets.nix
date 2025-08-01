let
  lib = (import <nixpkgs> { }).lib;
  inherit (import ../hax/hosts.nix { inherit lib; }) getAllKeys getAllHostkeys;
  # these need refactoring downstairs
  hostkeys = getAllHostkeys ../hosts;
  keyPaths = getAllKeys ../hosts;
  keys = hostkeys ++ map (v: builtins.readFile v) keyPaths;
in
with builtins;
readDir ./.
|> attrNames
|> filter (lib.hasSuffix ".age")
|> map (x: {
  name = x;
  value = {
    publicKeys = keys;
  };
})
|> lib.listToAttrs
