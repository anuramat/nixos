let
  # lib = import <lib>;
  lib = (import <nixpkgs> { }).lib;
  inherit (import ./hax/hosts.nix { inherit lib; }) getAllKeys;
  keys = getAllKeys ./hosts;
in
{
  "secret.age".publicKeys = keys;
}
