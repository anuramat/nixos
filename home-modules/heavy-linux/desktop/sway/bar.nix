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
      bars = {
        default = {
          # https://docs.rs/i3status-rs/latest/i3status_rs/blocks/index.html
          # TODO: idle inhibitor, kb layout indicator, wf-recorder thing
          blocks = [
            {
              block = "scratchpad";
            }
            {
              block = "sound";
            }
            {
              block = "backlight";
            }
            {
              alert = 10.0;
              block = "disk_space";
              info_type = "available";
              interval = 60;
              path = "/";
              warning = 20.0;
            }
            {
              block = "memory";
              format = " $icon $mem_free ";
              format_alt = " $icon $swap_used_percents ";
            }
            {
              block = "cpu";
              interval = 1;
            }
            {
              block = "battery";
            }
            {
              block = "time";
              format = " $timestamp.datetime(f:'%F %a %T') ";
              interval = 60;
            }
            {
              block = "tea_timer";
              done_cmd = "notify-send 'Tea is ready!' --urgency=critical";
            }
            {
              block = "pomodoro";
            }
          ];
        };
      };
    };
  };

}
