{
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    inputs.niri.homeModules.stylix
    inputs.niri.homeModules.niri
    ./keys.nix
  ];
  services.gnome-keyring.enable = lib.mkForce false;
  programs.niri = {
    enable = true;
    package = pkgs.niri;
    settings = {
    };
  };
}
