{
  pkgs,
  lib,
  inputs,
  ...
}:
{
  inputs = {
    inherit (inputs) nixpkgs flake-parts nix-unit;
  };
  tests = import ../tests {
    # TODO ROOT or move to root/tests the part or whatever
    inherit pkgs lib;
  };
}
