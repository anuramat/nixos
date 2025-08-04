# TODO is it possible to only look up nixpkgs stuff in cache
# TODO use max-jobs to fetch caches
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
  nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
  nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";

  # my stuff
  ctrlsn = mkInput "git+ssh://git@github.com/anuramat/ctrl.sn?ref=main";
  subcat = mkInput "github:anuramat/subcat";

  # forks
  mdformat-myst = mkInput "github:anuramat/mdformat-myst/dev";
  mdmath = mkInput "github:anuramat/mdmath.nvim";

  # `follows`
  mcphub = mkInput "github:ravitemer/mcphub.nvim";
  agenix = mkInput "github:yaxitech/ragenix";
  claude-desktop = mkInput "github:k3d3/claude-desktop-linux-flake";
  home-manager = mkInput "github:nix-community/home-manager/release-25.05";
  nixvim = mkInput "github:nix-community/nixvim";
  stylix = mkInput "github:danth/stylix/release-25.05";

  # no `follows`
  flake-utils.url = "github:numtide/flake-utils"; # no dependencies anyway
  neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay"; # has a cache
  nixos-hardware.url = "github:NixOS/nixos-hardware/master"; # too dangerous
  # these could work, but it's still a risk; TODO try
  codex.url = "github:anuramat/codex/latest";
  mcp-nixos.url = "github:utensils/mcp-nixos";
  nil.url = "github:oxalica/nil/main";
  spicetify-nix.url = "github:Gerg-L/spicetify-nix";

  # non flakes
  avante = mkNonFlake "github:yetone/avante.nvim/v0.0.27";
  blink-cmp-avante = mkNonFlake "github:Kaiser-Yang/blink-cmp-avante/v0.1.0";
  crush = mkNonFlake "github:charmbracelet/crush/v0.2.1"; # TODO set version
  tt-schemes = mkNonFlake "github:tinted-theming/schemes";
}
