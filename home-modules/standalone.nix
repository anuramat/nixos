{ inputs, ... }:
{
  imports = [
    inputs.agenix.homeManagerModules.default
    inputs.self.sharedModules.age
    inputs.self.sharedModules.stylix
    inputs.stylix.homeModules.stylix
  ];
  programs.home-manager.enable = true; # installs the home-manager CLI
}
