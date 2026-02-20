{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
{
  # TODO idle inputs default (from sway)
  imports = [
    inputs.niri.homeModules.stylix
    inputs.niri.homeModules.niri
    ./keys.nix
    ./bar.nix
  ];
  # TODO move out
  wayland.systemd.target = "graphical-session.target";
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
