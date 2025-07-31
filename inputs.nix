let
  mkInput = x: {
    url = x;
    inputs.nixpkgs.follows = "nixpkgs";
  };
in
{
  nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  nixpkgs-old.url = "github:nixos/nixpkgs/nixos-24.11";
  nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
  nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";

  ctrlsn = mkInput "git+ssh://git@github.com/anuramat/ctrl.sn?ref=main";
  mdformat-myst = mkInput "github:anuramat/mdformat-myst/dev";
  mdmath = mkInput "github:anuramat/mdmath.nvim";
  subcat = mkInput "github:anuramat/subcat";

  agenix = mkInput "github:yaxitech/ragenix";
  claude-desktop = mkInput "github:k3d3/claude-desktop-linux-flake";
  codex = mkInput "github:openai/codex";
  home-manager = mkInput "github:nix-community/home-manager/release-25.05";
  nixvim = mkInput "github:nix-community/nixvim";
  stylix = mkInput "github:danth/stylix/release-25.05";
  tt-schemes = mkInput "github:tinted-theming/schemes";

  flake-utils.url = "github:numtide/flake-utils"; # no dependencies anyway
  neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay"; # binary cache sake

  spicetify-nix.url = "github:Gerg-L/spicetify-nix"; # no data
  mcp-nixos.url = "github:utensils/mcp-nixos"; # no data
  nil.url = "github:oxalica/nil/main"; # no data
}
