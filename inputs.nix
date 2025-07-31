let
  mkInput = x: {
    url = x;
    inputs.nixpkgs.follows = "nixpkgs";
  };
  mkNonFlake = x: {
    url = x;
    flake = false;
  };
in
{
  nixpkgs-old.url = "github:nixos/nixpkgs/nixos-24.11";
  nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
  nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";

  ctrlsn = mkInput "git+ssh://git@github.com/anuramat/ctrl.sn?ref=main";
  mdformat-myst = mkInput "github:anuramat/mdformat-myst/dev";
  mdmath = mkInput "github:anuramat/mdmath.nvim";
  subcat = mkInput "github:anuramat/subcat";

  # `follows` as instructed (sure? TODO check)
  agenix = mkInput "github:yaxitech/ragenix";
  claude-desktop = mkInput "github:k3d3/claude-desktop-linux-flake";
  home-manager = mkInput "github:nix-community/home-manager/release-25.05";
  nixvim = mkInput "github:nix-community/nixvim";
  stylix = mkInput "github:danth/stylix/release-25.05";

  # definitely not:
  flake-utils.url = "github:numtide/flake-utils"; # no dependencies anyway
  neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay"; # has a cache
  nixos-hardware.url = "github:NixOS/nixos-hardware/master"; # too dangerous
  # not even a flake
  tt-schemes = {
    url = "github:tinted-theming/schemes";
    flake = false; # TODO how does this work
  };

  # these could work, but it's still a risk (TODO try)
  codex.url = "github:openai/codex";
  mcp-nixos.url = "github:utensils/mcp-nixos";
  nil.url = "github:oxalica/nil/main";
  spicetify-nix.url = "github:Gerg-L/spicetify-nix";

  # TODO check if any of these are in the community cache
  # TODO is it possible to only look up nixpkgs stuff in cache
  # TODO use max-jobs to fetch caches
  crush = mkNonFlake "github:charmbracelet/crush/nightly";
  gemini = mkNonFlake "github:google-gemini/gemini-cli/v0.1.15";
}
