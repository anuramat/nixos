{ pkgs, inputs, ... }:
{
  imports = [
    ./figtree.nix
    ./namu.nix
    ./wastebin.nix
    ./mdmath.nix
  ];
}
