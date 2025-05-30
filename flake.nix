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
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    subcat.url = "github:anuramat/subcat";
    ctrlsn.url = "git+ssh://git@github.com/anuramat/ctrl.sn?ref=main";
    mcp-nixos.url = "github:utensils/mcp-nixos";
  };
  outputs =
    inputs:
    let
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
            unstable = import inputs.nixpkgs-unstable {
              inherit (pkgscfg) config;
              inherit (pkgscfg.hostPlatform) system;
            };
            old = import inputs.nixpkgs-old {
              inherit (pkgscfg) config;
              inherit (pkgscfg.hostPlatform) system;
            };
          };
          modules = mkModules name ++ [
            ./nix/generic
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
    };
}
