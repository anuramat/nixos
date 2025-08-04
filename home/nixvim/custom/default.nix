{ pkgs, inputs, ... }:
{
  imports = [
    ./mcphub.nix
    ./figtree.nix
    ./namu.nix
    ./wastebin.nix
    ./mdmath.nix
    ./bracketed.nix
  ];
}
