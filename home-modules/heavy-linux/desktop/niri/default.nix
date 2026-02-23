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
      animations = {
        slowdown = 0.5;
      };
      screenshot-path = "${config.home.sessionVariables.XDG_PICTURES_DIR}/screen/shot_%F_%T.png";
      xwayland-satellite = {
        path = lib.getExe pkgs.xwayland-satellite;
        enable = true;
      };
      prefer-no-csd = true;
      hotkey-overlay.skip-at-startup = true;

      spawn-at-startup = [
        # { argv = [ ]; }
      ];

      layout = {
        empty-workspace-above-first = true;
      };

      input = {
        keyboard = {
          repeat-delay = 250;
          repeat-rate = 50;
          xkb.layout = "us,ru";
        };
        touchpad = {
          accel-profile = "adaptive";
          click-method = "clickfinger";
          drag = true;
          drag-lock = true;
          dwt = true;
          natural-scroll = true;
          scroll-method = "two-finger";
          tap = false;
        };
      };
    };
  };
}
