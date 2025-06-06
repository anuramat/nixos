{
  inputs = {
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
  };
  outputs =
    inputs:
    let

      inherit
        ((import ./helpers/machines.nix) {
          inherit inputs;
          machinesPath = ./os/machines;
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
        helpers = import ./helpers;
      };
      mkSystem =
        name:
        inputs.nixpkgs.lib.nixosSystem {
          specialArgs = commonArgs // {
            cluster = mkCluster name;
            # {{{1
            old =
              let
                pkgscfg = inputs.self.nixosConfigurations.${name}.config.nixpkgs;
              in
              import inputs.nixpkgs-old {
                inherit (pkgscfg) config;
                inherit (pkgscfg.hostPlatform) system;
              };
            # }}}
          };
          modules = [
            { home-manager.users.${user.username} = import ./home; }
            ./common
            ./os/options.nix
            ./os/generic
          ] ++ mkModules name;
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
      homeConfigurations.${user.username} = inputs.home-manager.lib.homeManagerConfiguration {
        specialArgs = commonArgs;
        modules = [
          ./home
          ./common
        ];
      };
    };
}
# vim: fdl=0 fdm=marker
