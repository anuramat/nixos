{
  inputs = {
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
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
    codex.url = "github:anuramat/codex";
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mdmath = {
      url = "github:anuramat/mdmath.nvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      nixpkgs,
      self,
      home-manager,
      nixvim,
      flake-utils,
      neovim-nightly-overlay,
      ...
    }@inputs:
    let

      inherit (nixpkgs) lib;
      hostnames = with builtins; ./hosts |> readDir |> attrNames |> filter (a: a != "external_keys.nix");
      helpers = import ./helpers { inherit lib inputs; };
      user = {
        username = "anuramat";
        fullname = "Arsen Nuramatov";
        email = "x@ctrl.sn";
        tz = "Europe/Berlin";
        locale = "en_US.UTF-8";
      };
      args = {
        inherit inputs user helpers;
      };
      mkSystem =
        name:
        let
          args2 = args // {
            cluster = helpers.root.mkCluster ./hosts hostnames name;
          };
        in
        lib.nixosSystem {
          specialArgs = args2;
          modules =
            [
              (
                { config, ... }:
                {
                  networking.hostName = name;
                  home-manager = {
                    extraSpecialArgs = args2;
                    users.${user.username} = ./home;
                  };

                }
              )
              ./system
              ./overlays.nix
              ./hosts/external_keys.nix
              inputs.stylix.nixosModules.stylix
              ./stylix.nix
            ]
            ++ [
              ./hosts/${name}
            ];
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
        # TODO check if this even builds
        specialArgs = args;
        modules = [
          ./home
          inputs.stylix.nixosModules.stylix
          ./stylix.nix
        ];
      };
    }
    // (flake-utils.lib.eachDefaultSystem (system: {
      packages.neovim = nixvim.legacyPackages.${system}.makeNixvimWithModule {
        inherit system;
        extraSpecialArgs = { inherit inputs; };
        # TODO figure out how to add overlays.nix to standalone nixvim
        module = ./home/nixvim;
      };
    }));
}
# vim: fdl=0 fdm=marker
