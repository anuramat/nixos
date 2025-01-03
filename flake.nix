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

      x =
        assert false;
        2;

      u = import ./nix/utils.nix;
      m = (import ./nix/machines) {
        inherit u;
        inherit (inputs.nixpkgs) lib;
      };

      mkSystem =
        name:
        let
          machines = m.machines name;
          user = (import ./nix/user.nix);
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
                config = {
                  allowUnfree = true; # try recursive? TODO
                };
                system = machines.this.platform;
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
      nixosConfigurations = builtins.listToAttrs (map mkSystem m.hostnames);
    };
}
