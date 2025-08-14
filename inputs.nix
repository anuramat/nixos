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
  # base
  nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
  nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
  flake-parts.url = "github:hercules-ci/flake-parts";
  nix-unit = mkInput "github:nix-community/nix-unit/v2.30.0";
  nur = mkInput "github:nix-community/NUR";

  # my stuff
  ctrlsn = mkInput "git+ssh://git@github.com/anuramat/ctrl.sn?ref=main";
  subcat = mkInput "github:anuramat/subcat";
  gothink = mkInput "github:anuramat/gothink";
  modagent = mkInput "github:anuramat/modagent";
  todo = mkNonFlake "github:anuramat/todo";
  figtree = mkInput "github:anuramat/figtree.nvim";

  # forks
  mods.url = "github:anuramat/mods";
  mdformat-myst = mkInput "github:anuramat/mdformat-myst/dev"; # I think I broke the formatter...
  mdmath.url = "github:anuramat/mdmath.nvim";

  # `follows`
  mcphub = mkInput "github:ravitemer/mcphub.nvim";
  agenix = mkInput "github:yaxitech/ragenix";
  claude-desktop = mkInput "github:k3d3/claude-desktop-linux-flake";
  home-manager = mkInput "github:nix-community/home-manager/release-25.05";
  nixvim = mkInput "github:nix-community/nixvim";
  stylix = mkInput "github:danth/stylix/release-25.05";
  mcp-nixos = mkInput "github:utensils/mcp-nixos";
  nil = mkInput "github:oxalica/nil/main";
  spicetify-nix = mkInput "github:Gerg-L/spicetify-nix";

  # no `follows`
  neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay"; # has a cache
  nixos-hardware.url = "github:NixOS/nixos-hardware/master"; # too dangerous

  # non flakes
  avante = mkNonFlake "github:yetone/avante.nvim/v0.0.27";
  blink-cmp-avante = mkNonFlake "github:Kaiser-Yang/blink-cmp-avante/v0.1.0";
  crush = mkNonFlake "github:charmbracelet/crush/v0.2.1";
  tt-schemes = mkNonFlake "github:tinted-theming/schemes";

  musnix.url = "github:musnix/musnix";
  nix-topology.url = "github:oddlama/nix-topology";
  treefmt-nix.url = "github:numtide/treefmt-nix";
  ez-configs = {
    url = "github:ehllie/ez-configs";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.flake-parts.follows = "flake-parts";
  };
}
