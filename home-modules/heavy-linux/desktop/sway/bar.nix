{ lib, pkgs, ... }:
let
  inherit (lib) getExe;
in
{

  wayland.windowManager.sway.config.bars =
    let
      bin = getExe pkgs.i3status-rust;
    in
    [
      {
        statusCommand = "${bin} config-default.toml";
        fonts = [
          "pango:monospace 12.0"
        ];
      }
    ];
  programs = {
    i3status-rust = {
      enable = true;
      # bars = {
      #   default = {
      #     blocks = [
      #       {
      #         alert = 10.0;
      #         block = "disk_space";
      #         info_type = "available";
      #         interval = 60;
      #         path = "/";
      #         warning = 20.0;
      #       }
      #       {
      #         block = "memory";
      #         format = " $icon mem_used_percents ";
      #         format_alt = " $icon $swap_used_percents ";
      #       }
      #       {
      #         block = "cpu";
      #         interval = 1;
      #       }
      #       {
      #         block = "load";
      #         format = " $icon $1m ";
      #         interval = 1;
      #       }
      #       {
      #         block = "sound";
      #       }
      #       {
      #         block = "time";
      #         format = " $timestamp.datetime(f:'%a %d/%m %R') ";
      #         interval = 60;
      #       }
      #     ];
      #   };
      # };
    };
  };
  #       modules = {
  #         modules-left = [
  #           "pulseaudio"
  #           "backlight"
  #           "idle_inhibitor"
  #           "sway/language"
  #           "mpris"
  #         ];
  #         modules-center = [
  #           "custom/rec"
  #           "sway/workspaces"
  #           "sway/scratchpad"
  #         ];
  #         modules-right = [
  #           "tray"
  #           "disk"
  #           "battery"
  #           "clock"
  #         ];
  #       };
}
