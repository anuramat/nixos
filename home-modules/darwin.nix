{ inputs, ... }:
{
  imports = [
    inputs.mac-app-util.homeManagerModules.default
  ];

  gui = "darwin";
}
