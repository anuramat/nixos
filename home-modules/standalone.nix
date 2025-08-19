{ inputs, ... }:
{
  nixpkgs.overlays = [
    inputs.self.overlays.default
  ];
  imports = [
    inputs.agenix.homeManagerModules.default
    inputs.self.genericModules.age
    inputs.self.genericModules.stylix
    inputs.stylix.homeModules.stylix
  ];
}
