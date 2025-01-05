{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    zen-browser.url = "github:MarceColl/zen-browser-flake";
    wallust.url = "git+https://codeberg.org/explosion-mental/wallust?ref=master";
  };
  outputs =
    inputs:

    let
      u = import ./nix/utils.nix;
      inherit
        ((import ./nix/machines) {
          inherit u inputs;
          inherit (inputs.nixpkgs) lib;
        })
        hostnames
        mkMachines
        ;

      mkSystem =
        name:
        let
          machines = mkMachines name;
          user = (import ./nix/user.nix);
          nixpkgsOption = inputs.self.nixosConfigurations.${name}.config.nixpkgs;
        in
        {
          inherit name;
          value = inputs.nixpkgs.lib.nixosSystem {
            specialArgs = {
              inherit
                inputs
                user
                machines
                u
                ;
              unstable = import inputs.nixpkgs-unstable {
                inherit (nixpkgsOption) config;
                inherit (nixpkgsOption.hostPlatform) system;
              };
            };

            modules = [
              machines.this.module
              ./nix/common
            ];
          };
        };
    in
    {
      nixosConfigurations = builtins.listToAttrs (map mkSystem hostnames);
    };
}
