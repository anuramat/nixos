{ pkgs, ... }:
{
  programs.nix-index = {
    enableBashIntegration = false; # annoying on "command not found"
    enable = true;
  };
  home.packages = with pkgs; [
    nix-web # derivation viewer
    nix-search # package search

    nix-output-monitor # `nom` -- pretty nix build output
    nix-tree # dep tree

    nix-diff
    # nix diffs:
    nvd
    dix

    nix-unit
  ];
}
