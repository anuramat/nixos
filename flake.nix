{
  outputs =
    {
      nixpkgs,
      home-manager,
      nixvim,
      flake-utils,
      ...
    }@inputs:
    let
      inherit (nixpkgs) lib;
      hax = import ./hax { inherit lib inputs; };
      hostnames = hax.hosts.getHostnames ./hosts;
      user = {
        username = "anuramat";
        fullname = "Arsen Nuramatov";
        email = "x@ctrl.sn";
        tz = "Europe/Berlin";
        locale = "en_US.UTF-8";
      };
      args = {
        inherit inputs user hax;
      };
      mkSystem =
        name:
        let
          args2 = args // {
            cluster = hax.hosts.mkCluster ./hosts hostnames name;
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

              ./common/overlays.nix

              inputs.stylix.nixosModules.stylix
              ./common/stylix.nix

              ./hosts/external_keys.nix
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

          ./common/overlays.nix
          inputs.stylix.nixosModules.stylix
          ./common/stylix.nix
        ];
      };
    }
    // (flake-utils.lib.eachDefaultSystem (system: {
      packages.neovim = nixvim.legacyPackages.${system}.makeNixvimWithModule {
        inherit system;
        extraSpecialArgs = { inherit inputs hax; };
        module = {
          imports = [
            ./common/overlays.nix
            ./home/nixvim
          ];
        };
      };
    }));

  inputs = {
    # TODO make everything follow? make a helper?
    agenix.url = "github:yaxitech/ragenix";
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-old.url = "github:nixos/nixpkgs/nixos-24.11";
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
}
# vim: fdl=0 fdm=marker
