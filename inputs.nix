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
  agenix = mkInput "github:yaxitech/ragenix";
  flake-parts.url = "github:hercules-ci/flake-parts";
  home-manager = mkInput "github:nix-community/home-manager/release-25.05";
  musnix.url = "github:musnix/musnix";
  neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay"; # no follows: has a cache
  nix-topology.url = "github:oddlama/nix-topology";
  nix-unit = mkInput "github:nix-community/nix-unit/v2.30.0";
  nixos-hardware.url = "github:NixOS/nixos-hardware/master"; # no follows: too dangerous
  nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
  nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
  nixvim = mkInput "github:nix-community/nixvim";
  nur = mkInput "github:nix-community/NUR";
  stylix = mkInput "github:danth/stylix/release-25.05";
  files.url = "github:mightyiam/files";
  treefmt-nix.url = "github:numtide/treefmt-nix";
  git-hooks-nix.url = "github:cachix/git-hooks.nix";
  ez-configs = {
    url = "github:ehllie/ez-configs";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.flake-parts.follows = "flake-parts";
  };

  # my stuff
  ctrlsn = mkInput "git+ssh://git@github.com/anuramat/ctrl.sn?ref=main";
  figtree = mkInput "github:anuramat/figtree.nvim";
  gothink = mkInput "github:anuramat/gothink";
  modagent = mkInput "github:anuramat/modagent";
  subcat = mkInput "github:anuramat/subcat";
  todo = mkNonFlake "github:anuramat/todo";

  # forks
  mdformat-myst = mkInput "github:anuramat/mdformat-myst/dev"; # I think I broke the formatter...
  mdmath.url = "github:anuramat/mdmath.nvim";
  mods.url = "github:anuramat/mods";

  # misc
  claude-desktop = mkInput "github:k3d3/claude-desktop-linux-flake";
  mcp-nixos = mkInput "github:utensils/mcp-nixos";
  mcphub = mkInput "github:ravitemer/mcphub.nvim";
  nil = mkInput "github:oxalica/nil/main";
  spicetify-nix = mkInput "github:Gerg-L/spicetify-nix";

  # non flakes
  avante = mkNonFlake "github:yetone/avante.nvim/v0.0.27";
  blink-cmp-avante = mkNonFlake "github:Kaiser-Yang/blink-cmp-avante/v0.1.0";
  crush = mkNonFlake "github:charmbracelet/crush/v0.2.1";
  tt-schemes = mkNonFlake "github:tinted-theming/schemes";
}
