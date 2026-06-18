{ inputs, ... }:
{
  imports = [
    inputs.agenix.homeManagerModules.default
    inputs.self.sharedModules.age
    inputs.self.sharedModules.nixpkgs
    inputs.self.sharedModules.stylix
    inputs.stylix.homeModules.stylix
  ];
}
