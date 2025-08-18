{ inputs, ... }:
{
  imports = [
    ./agents
    ./editor.nix
    ./email.nix
    ./gui
    ./lang
    ./mime
    inputs.spicetify-nix.homeManagerModules.spicetify
    inputs.nixvim.homeModules.nixvim
  ];
}
