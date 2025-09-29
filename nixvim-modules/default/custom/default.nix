{ pkgs, inputs, ... }:
{
  imports = [
    ./figtree.nix
    ./namu.nix
    ./wastebin.nix
    ./bracketed.nix
  ];
}
