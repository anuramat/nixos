{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    inputs.niri.homeModules.stylix
    inputs.niri.homeModules.niri
    ./keys.nix
    ./waybar.nix
  ];
  services.gnome-keyring.enable = lib.mkForce false;
  programs.niri = {
    enable = true;
    package = pkgs.niri;
    settings = {
      screenshot-path = "${config.home.sessionVariables.XDG_PICTURES_DIR}/screen/shot_%F_%T.png";
      prefer-no-csd = true;
      hotkey-overlay.skip-at-startup = true;
    };
  };
}
