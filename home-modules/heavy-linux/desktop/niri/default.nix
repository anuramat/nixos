{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:

# systemd = {
#   xdgAutostart = true;
#   variables =
#     let
#       defaults = [
#         "DISPLAY"
#         "WAYLAND_DISPLAY"
#         "SWAYSOCK"
#         "XDG_CURRENT_DESKTOP"
#         "XDG_SESSION_TYPE"
#         "NIXOS_OZONE_WL"
#         "XCURSOR_THEME"
#         "XCURSOR_SIZE"
#       ];
#     in
#     defaults
#     ++ [
#       "DBUS_SESSION_BUS_ADDRESS" # for proton-bridge
#     ];

# --------------
# wayland.windowManager.sway.config.input = {
#   "*" = {
#     accel_profile = "flat";
#     repeat_delay = "250";
#     repeat_rate = "50";
#     xkb_layout = "us,ru";
#     xkb_options = "grp:alt_space_toggle";
#   };
#
#   "type:touchpad" = {
#     accel_profile = "adaptive";
#     click_method = "clickfinger";
#     drag = "enabled"; # tap-drag
#     drag_lock = "enabled"; # grace period for tap-drag
#     dwt = "enabled";
#     natural_scroll = "enabled";
#     scroll_method = "two_finger";
#     tap = "disabled";
#   };
#
#   "5426:98:Razer_Razer_Atheris_-_Mobile_Gaming_Mouse_Keyboard" = {
#   };
#
#   "12951:6519:ZSA_Technology_Labs_Voyager" = {
#     rotation_angle = "30";
#   };
#
#   "5426:138:Razer_Razer_Viper_Mini" = {
#   };
#
#   # anuramat-t480
#   "1:1:AT_Translated_Set_2_keyboard" = {
#   };
#
#   "1739:0:Synaptics_TM3276-022" = {
#     events = "disabled";
#   };
#
#   "2:10:TPPS/2_IBM_TrackPoint" = {
#     pointer_accel = "0.7";
#     accel_profile = "adaptive";
#   };
# };
{
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
