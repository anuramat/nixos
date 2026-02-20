{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:
{
  imports = [
    inputs.niri.homeModules.stylix
    inputs.niri.homeModules.niri
  ];
  services.gnome-keyring.enable = lib.mkForce false;
  programs.niri = {
    enable = true;
    package = pkgs.niri;
    settings = {
      binds = {
        "Mod+semicolon".action.spawn = "foot";
      };
    };
  };
}
