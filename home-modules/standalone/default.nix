{ inputs, ... }:
{
  nixpkgs.overlays = [
    inputs.self.overlays.default
  ];
  imports = [
    inputs.stylix.homeModules.stylix
    inputs.self.modules.stylix
  ];
}
