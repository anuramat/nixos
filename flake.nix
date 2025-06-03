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
      username = "anuramat";
      epsilon =
        path: path |> builtins.readDir |> builtins.attrNames |> builtins.filter (a: a != "default.nix");

      inherit ((import ./nix/machines) { inherit inputs epsilon; })
        hostnames
        mkCluster
        mkModules
        ;

      mkSystem =
        name:
        let
          pkgscfg = inputs.self.nixosConfigurations.${name}.config.nixpkgs;
        in
        inputs.nixpkgs.lib.nixosSystem {
          specialArgs = {
            cluster = mkCluster name;
            inherit inputs;
            helpers = import ./nix/helpers { inherit (inputs.nixpkgs) lib; };
            dummy = path: path |> epsilon |> map (name: path + /${name});
            old = import inputs.nixpkgs-old {
              inherit (pkgscfg) config;
              inherit (pkgscfg.hostPlatform) system;
            };
          };
          modules = mkModules name ++ [
            ./nix/generic
            inputs.stylix.nixosModules.stylix
            inputs.home-manager.nixosModules.home-manager
            (
              { config, ... }:
              {
                home-manager = {
                  backupFileExtension = "hmbackup";
                  useGlobalPkgs = true;
                  useUserPackages = true;
                  users.${config.user.username} = import ./hm; # WARN value is a home manager module, not nixos
                };
              }
            )
          ];
        };
    in
    {
      nixosConfigurations =
        hostnames
        |> map (name: {
          inherit name;
          value = mkSystem name;
        })
        |> builtins.listToAttrs;
      homeConfigurations.${username} = inputs.home-manager.lib.homeManagerConfiguration {
        modules = [
          ./hm
        ];
      };
    };
}
