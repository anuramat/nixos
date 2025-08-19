{ inputs, ... }:
{
  nixpkgs.overlays = [
    inputs.self.overlays.default
  ];
  imports = [
    inputs.agenix.homeManagerModules.default
    inputs.self.sharedModules.stylix
    inputs.stylix.homeModules.stylix
  ];
}
