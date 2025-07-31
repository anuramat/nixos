let
  mkInput = x: {
    url = "github:${x}";
    inputs.nixpkgs.follows = "nixpkgs";
  };
in
{
  nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
  nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
  nixpkgs-old.url = "github:nixos/nixpkgs/nixos-24.11";
  nixos-hardware.url = "github:NixOS/nixos-hardware/master";

  agenix = mkInput "yaxitech/ragenix";
  claude-desktop = mkInput "k3d3/claude-desktop-linux-flake";
  codex = mkInput "openai/codex";
  ctrlsn.url = "git+ssh://git@github.com/anuramat/ctrl.sn?ref=main";
  flake-utils = mkInput "numtide/flake-utils";
  home-manager = mkInput "nix-community/home-manager/release-25.05";
  mcp-nixos = mkInput "utensils/mcp-nixos";
  mdformat-myst = mkInput "anuramat/mdformat-myst/dev";
  mdmath = mkInput "anuramat/mdmath.nvim";
  neovim-nightly-overlay = mkInput "nix-community/neovim-nightly-overlay";
  nil = mkInput "oxalica/nil/main";
  nixvim = mkInput "nix-community/nixvim";
  spicetify-nix = mkInput "Gerg-L/spicetify-nix";
  stylix = mkInput "danth/stylix/release-25.05";
  subcat = mkInput "anuramat/subcat";
  tt-schemes = mkInput "tinted-theming/schemes";
}
