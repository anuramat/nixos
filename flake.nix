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
      user = import ./nix/user.nix;
      unstable = import inputs.nixpkgs-unstable {
        config = {
          allowUnfree = true;
          # cudaSupport = true;
          # cudnnSupoprt = true;
        };
        system = "x86_64-linux";
      };
      specialArgs = { inherit user unstable inputs; };
      system = name: {
        inherit name;
        value = inputs.nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          modules = [
            ./nix/machines/${name}
            ./nix/common
          ];
        };
      };
      machines = ./nix/machines |> builtins.readDir |> builtins.attrNames;
    in
    {
      nixosConfigurations = builtins.listToAttrs (map system machines);
    };
}
