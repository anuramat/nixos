{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    zen-browser.url = "github:MarceColl/zen-browser-flake";
  };
  outputs =
    inputs:
    let
      inherit (inputs.nixpkgs.lib.attrsets) genAttrs;
      machineDir = ./nix/machines;
      hostnames = machineDir |> builtins.readDir |> builtins.attrNames;
      machines = genAttrs hostnames (x: import (machineDir + /${x}/out.nix));

      unstable = import inputs.nixpkgs-unstable {
        config = {
          allowUnfree = true;
          # cudaSupport = true;
          # cudnnSupoprt = true;
        };
        system = "x86_64-linux";
      };

      system = name: {
        inherit name;
        value = inputs.nixpkgs.lib.nixosSystem {

          specialArgs = {
            inherit
              unstable
              inputs
              ;
            user = (import ./nix/user.nix) {
              hostname = name;
              inherit machines;
              lib = inputs.nixpkgs.lib;
            };
            dummy = import ./nix/dummy.nix;
          };

          modules = [
            (machineDir + /${name})
            ./nix/common
          ];
        };
      };
    in
    {
      nixosConfigurations = builtins.listToAttrs (map system hostnames);
    };
}
