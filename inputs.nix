{
  nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
  nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
  nixpkgs-old.url = "github:nixos/nixpkgs/nixos-24.11";

  nixos-hardware.url = "github:NixOS/nixos-hardware/master";

  home-manager = {
    url = "github:nix-community/home-manager/release-25.05";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
  nixvim = {
    url = "github:nix-community/nixvim";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  stylix = {
    url = "github:danth/stylix/release-25.05";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake-utils.url = "github:numtide/flake-utils";
  agenix.url = "github:yaxitech/ragenix";

  subcat.url = "github:anuramat/subcat";
  ctrlsn.url = "git+ssh://git@github.com/anuramat/ctrl.sn?ref=main";

  mdmath = {
    url = "github:anuramat/mdmath.nvim";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  mdformat-myst = {
    url = "github:anuramat/mdformat-myst/dev";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  mcp-nixos.url = "github:utensils/mcp-nixos";
  nil.url = "github:oxalica/nil/main";
  codex.url = "github:openai/codex";
  spicetify-nix.url = "github:Gerg-L/spicetify-nix";
  tt-schemes = {
    url = "github:tinted-theming/schemes";
    flake = false;
  };
  claude-desktop = {
    url = "github:k3d3/claude-desktop-linux-flake";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
