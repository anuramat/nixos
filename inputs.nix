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
  mac-app-util.url = "github:hraban/mac-app-util";

  flake-parts.url = "github:hercules-ci/flake-parts";
  home-manager = mkInput "github:nix-community/home-manager/release-25.05";
  neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay"; # no follows: has a cache
  nix-topology.url = "github:oddlama/nix-topology";
  nix-unit = mkInput "github:nix-community/nix-unit/v2.30.0";
  nixos-hardware.url = "github:NixOS/nixos-hardware/master"; # no follows: too dangerous
  nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
  nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
  nixvim = mkInput "github:nix-community/nixvim/nixos-25.05";
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
  subcat = mkInput "github:anuramat/subcat";
  todo = mkInput "github:anuramat/todo";

  # forks
  mods.url = "github:anuramat/mods/dev";
  zotero-mcp.url = "github:anuramat/zotero-mcp";
  duckduckgo-mcp-server.url = "github:anuramat/duckduckgo-mcp-server/dev";
  protonmail-bridge = mkNonFlake "github:anuramat/proton-bridge/dev";
  html2text.url = "github:anuramat/html2text/dev";

  # misc
  mcp-nixos.url = "github:utensils/mcp-nixos";
  mcphub = mkInput "github:ravitemer/mcphub.nvim";
  nil = mkInput "github:oxalica/nil/main";
  spicetify-nix = mkInput "github:Gerg-L/spicetify-nix";
  statix.url = "github:oppiliappan/statix/master";
  deadnix.url = "github:astro/deadnix/main";
  nixd.url = "github:nix-community/nixd/2.7.0";

  # non flakes
  avante = mkNonFlake "github:yetone/avante.nvim/main";
  blink-cmp-avante = mkNonFlake "github:Kaiser-Yang/blink-cmp-avante";
  tt-schemes = mkNonFlake "github:tinted-theming/schemes";
  base16-mutt = mkNonFlake "github:josephholsten/base16-mutt";
}
