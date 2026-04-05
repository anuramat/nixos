{ pkgs, ... }:
{
  programs.nix-index = {
    enableBashIntegration = false; # annoying on "command not found"
    enable = true;
  };
  home.packages = with pkgs; [
    nix-web # derivation viewer
    nix-search # package search

    nix-output-monitor # `nom`

    nix-diff
    # nix diffs:
    nvd
    dix

    nix-unit
  ];
}
