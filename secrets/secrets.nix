let
  # lib = import <lib>;
  lib = (import <nixpkgs> { }).lib;
  inherit (import ../hax/hosts.nix { inherit lib; }) getAllKeys;
  keyPaths = getAllKeys ../hosts;
  keys = map (v: builtins.readFile v) keyPaths;
in
{
  "ghmcp.age".publicKeys = keys;
  "litellm.age".publicKeys = keys;
}
