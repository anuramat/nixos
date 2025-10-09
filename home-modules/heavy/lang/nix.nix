{ pkgs, ... }:
{
  programs.nix-index.enable = true;
  home.packages = with pkgs; [
    nix-web # derivation viewer
    nix-search # package search

    nix-diff
    nvd # nix diff
    # dix # nix diff # XXX not in stable yet

    nix-unit

    devenv # nix for retards
  ];
}
