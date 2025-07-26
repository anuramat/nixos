let
  # lib = import <lib>;
  lib = (import <nixpkgs> { }).lib;
  inherit (import ../hax/hosts.nix { inherit lib; }) getAllKeys getAllHostkeys;
  hostkeys = getAllHostkeys ../hosts;
  keyPaths = getAllKeys ../hosts;
  keys = hostkeys ++ map (v: builtins.readFile v) keyPaths;
in
{
  "ghmcp.age".publicKeys = keys;
  "litellm.age".publicKeys = keys;
}
