{
  inputs = {
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
    avante = {
      url = "github:anuramat/avante.nvim/flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    wastebin-nvim = {
      url = "github:anuramat/wastebin.nvim/flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs-old.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:danth/stylix/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    subcat.url = "github:anuramat/subcat";
    ctrlsn.url = "git+ssh://git@github.com/anuramat/ctrl.sn?ref=main";
    mcp-nixos.url = "github:utensils/mcp-nixos";
    nil.url = "github:oxalica/nil/main";
    nixCats.url = "github:BirdeeHub/nixCats-nvim";
    codex.url = "github:anuramat/codex";
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      nixpkgs,
      self,
      nixpkgs-old,
      home-manager,
      nixvim,
      flake-utils,
      neovim-nightly-overlay,
      ...
    }@inputs:
    let

      inherit (nixpkgs) lib;
      epsilon = with builtins; path: path |> readDir |> attrNames |> filter (a: a != "default.nix");
      inherit
        ((import ./os/machines) {
          inherit inputs epsilon;
        })
        hostnames
        mkCluster
        mkModules
        ;

      user = {
        username = "anuramat";
        fullname = "Arsen Nuramatov";
        email = "x@ctrl.sn";
      };
      commonArgs = {
        inherit inputs user;
        helpers = import ./helpers { inherit lib; };
      };
      mkSystem =
        name:
        let
          cluster = mkCluster name;
        in
        lib.nixosSystem {
          specialArgs = commonArgs // {
            inherit cluster;
            # {{{1
            old =
              let
                pkgscfg = self.nixosConfigurations.${name}.config.nixpkgs;
              in
              import nixpkgs-old {
                inherit (pkgscfg) config;
                inherit (pkgscfg.hostPlatform) system;
              };
            # }}}
          };
          modules =
            [
              {
                home-manager = {
                  extraSpecialArgs = commonArgs;
                  users.${user.username} = import ./home;
                };
              }
              ./common
              ./os/generic
            ]
            ++ mkModules name
            ++ (
              if cluster.this.server then
                [
                  ./os/remote.nix
                ]
              else
                [
                  ./os/local
                ]
            );
        };
    in
    {
      nixosConfigurations =
        hostnames
        |> map (hostname: {
          name = hostname;
          value = mkSystem hostname;
        })
        |> builtins.listToAttrs;
      homeConfigurations.${user.username} = home-manager.lib.homeManagerConfiguration {
        specialArgs = commonArgs;
        # TODO check stylix module sharing between home-manager and nixos
        # TODO check home-manager on a non-nixos system
        modules = [
          ./home
          ./common
          (
            { pkgs, ... }:
            {
              home.packages = [ self.packages.${pkgs.stdenv.system}.neovim ];
            }
          )
        ];
      };
    }
    // (flake-utils.lib.eachDefaultSystem (system: {
      packages.neovim = nixvim.legacyPackages.${system}.makeNixvimWithModule {
        pkgs = import nixpkgs { inherit system; };
        extraSpecialArgs = {
          myInputs = inputs;
        };
        module = ./nixvim;
      };
    }));
}
# vim: fdl=0 fdm=marker
