{ inputs, ... }:
{
  imports = [
    ./editor.nix
    ./gui
    inputs.nixvim.homeModules.nixvim
    ./lang
    ./email.nix
    inputs.spicetify-nix.homeManagerModules.spicetify
    ./packages.nix
  ];
}
