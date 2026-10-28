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
    ./autologin.nix
    ./extra-config.nix
    ./keys.nix
    ./nirimap.nix
    ./shortcuts.nix
    ./zsa-tap.nix
  ];
  wayland.systemd.target = "niri.service"; # NOTE using graphical-session.target breaks services that have ConditionEnvironment=WAYLAND_DISPLAY, because they start too early -- before niri sets variables
  xdg.configFile."systemd/user/niri.service.d/override.conf".text =
    let
      path = lib.makeBinPath [
        pkgs.systemd
        pkgs.dbus
        pkgs.coreutils
        pkgs.gawk
        pkgs.bash
        config.programs.ghostty.package
      ];
    in
    # systemd
    ''
      [Service]
      Environment=PATH=${path}
    '';
  services.gnome-keyring.enable = lib.mkForce false;
  programs.niri = {
    enable = true;
    package = pkgs.niri;
    extraConfig = ''
      recent-windows {
          off
      }
    '';
    settings = {
      animations = {
        slowdown = 0.5;
      };
      screenshot-path = "${config.home.sessionVariables.XDG_PICTURES_DIR}/screen/shot_%F_%T.png";
      xwayland-satellite.path = lib.getExe pkgs.xwayland-satellite;
      prefer-no-csd = true;
      hotkey-overlay.skip-at-startup = true;

      window-rules = [
        {
          matches = [ { is-active = false; } ];
          opacity = 0.9;
        }
      ];
      layout = {
        border = {
          width = 0;
        };
        focus-ring = {
          # active.color = "#008080";
          enable = true;
        };
        background-color = config.lib.stylix.colors.withHashtag.base00;
        empty-workspace-above-first = true;
        shadow = {
          enable = true;
          color = "#000000FF";
          inactive-color = "#00000000";
        };
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
          tap = lib.mkDefault false;
        };
      };
    };
  };
}
