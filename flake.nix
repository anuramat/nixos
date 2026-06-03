# TODO use max-jobs to fetch caches
{
  inputs = {
    agenix = {
      url = "github:yaxitech/ragenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mac-app-util.url = "github:hraban/mac-app-util";

    flake-parts.url = "github:hercules-ci/flake-parts";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    nix-topology.url = "github:oddlama/nix-topology";
    nix-unit = {
      url = "github:nix-community/nix-unit/v2.30.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nix-strix-halo = {
      url = "github:hellas-ai/nix-strix-halo";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-unstable-misc.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixvim.url = "github:nix-community/nixvim/nixos-26.05";
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:danth/stylix/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix.url = "github:numtide/treefmt-nix";
    git-hooks-nix.url = "github:cachix/git-hooks.nix";
    ez-configs = {
      url = "github:ehllie/ez-configs";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
    nix-auth = {
      url = "github:numtide/nix-auth";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # my stuff
    ctrlsn = {
      url = "git+ssh://git@github.com/anuramat/ctrl.sn?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    figtree = {
      url = "github:anuramat/figtree.nvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    subcat = {
      url = "github:anuramat/subcat";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    todo = {
      url = "github:anuramat/todo";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vicode.url = "github:anuramat/vicode/dev";

    # forks
    mods.url = "github:anuramat/mods/dev";
    protonmail-bridge = {
      url = "github:anuramat/proton-bridge/dev";
      flake = false;
    };
    html2text.url = "github:anuramat/html2text/dev";

    claude-code = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    codex = {
      url = "github:sadjow/codex-cli-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    copilot-cli = {
      url = "github:scarisey/copilot-cli-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hermes.url = "github:NousResearch/hermes-agent";
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zed-editor.url = "github:zed-industries/zed";
    nil = {
      url = "github:oxalica/nil/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    statix.url = "github:oppiliappan/statix/master";
    deadnix.url = "github:astro/deadnix/main";

    tt-schemes = {
      url = "github:tinted-theming/schemes";
      flake = false;
    };
    base16-mutt = {
      url = "github:josephholsten/base16-mutt";
      flake = false;
    };
    pass-secret-service = {
      url = "github:grimsteel/pass-secret-service/v0.7.0";
      flake = false;
    };
  };

  outputs = args: import ./outputs.nix args;
}
