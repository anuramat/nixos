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
    user = {
      username = "anuramat";
      fullname = "Arsen Nuramatov";
      timezone = "Etc/GMT-2"; # WARN inverted offset
      defaultLocale = "en_US.UTF-8";
    };
    unstable = import inputs.nixpkgs-unstable {
      config.allowUnfree = true;
      system = "x86_64-linux";
    };
    overlays = with inputs; [
      # neovim-nightly-overlay.overlays.default # broken atm
      nix-alien.overlays.default
    ];
  in {
    nixosConfigurations = {
      anuramat-ll7 = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit user unstable;};
        modules = [
          ./configuration.nix

          ./machines/anuramat-ll7.nix
          inputs.nixos-hardware.nixosModules.common-cpu-intel
          inputs.nixos-hardware.nixosModules.common-gpu-intel
          (_: {
            system.stateVersion = "24.05";
            networking.hostName = "anuramat-ll7";
            nixpkgs.overlays = overlays;
            boot.initrd.luks.devices."luks-a5b4aba2-047f-4828-bce3-fd9907ad99c0".device = "/dev/disk/by-uuid/a5b4aba2-047f-4828-bce3-fd9907ad99c0";
          })
        ];
      };
    };
  };
}
