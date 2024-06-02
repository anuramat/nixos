{
  inputs = {
    # nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    # modules
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    # overlays
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    # packages
    nix-alien.url = "github:thiagokokada/nix-alien";
  };
  outputs = {nixpkgs, ...} @ inputs: let
    user = import ./user.nix;
    unstable = import inputs.nixpkgs-unstable {
      config.allowUnfree = true;
      inherit (user) system;
    };
    overlays = with inputs; [
      neovim-nightly-overlay.overlay
    ];
  in {
    nixosConfigurations.${user.hostname} = nixpkgs.lib.nixosSystem {
      inherit (user) system;
      specialArgs = {
        inherit unstable user;
      };
      modules = [
        ./configuration.nix

        # hardware tweaks
        inputs.nixos-hardware.nixosModules.common-cpu-intel
        inputs.nixos-hardware.nixosModules.common-gpu-nvidia
        inputs.nixos-hardware.nixosModules.common-pc-laptop
        inputs.nixos-hardware.nixosModules.common-pc-laptop-ssd
        inputs.nixos-hardware.nixosModules.common-hidpi

        # TODO is this even useful
        (_: {
          environment.systemPackages = [
            inputs.nix-alien.packages.${user.system}.nix-alien
          ];
          nixpkgs.overlays = overlays;
        })
      ];
    };
  };
}
