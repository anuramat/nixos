{ inputs, ... }:
{
  imports = [
    inputs.stylix.nixosModules.stylix
    ./stylix.nix
    ./overlays.nix
  ];
}
