# tablet mode (screen folded back): a user service, started and stopped by
# niri's switch events, rotates the panel with the accelerometer, bumps its
# scale for fingers, and shows an on-screen keyboard
{
  inputs,
  pkgs,
  lib,
  ...
}:
let
  inherit (inputs.self.consts.user) username;
  output = "eDP-1";
in
{
  home-manager.users.${username} =
    { config, ... }:
    let
      niri = lib.getExe config.programs.niri.package;
      rotate = pkgs.writeShellScript "tablet-rotate" ''
        ${pkgs.iio-sensor-proxy}/bin/monitor-sensor --accel | while read -r line; do
          # "... (orientation: normal)" on start, "... changed: left-up" after;
          # lying flat reports "undefined", which keeps the current rotation
          o=''${line##*: }
          case ''${o%)} in
            normal) t=normal ;;
            left-up) t=90 ;;
            bottom-up) t=180 ;;
            right-up) t=270 ;;
            *) continue ;;
          esac
          ${niri} msg output ${output} transform "$t"
        done
      '';
    in
    {
      programs.niri = {
        settings = {
          input.touch.map-to-output = output;
          switch-events = {
            tablet-mode-on.action.spawn = [
              "systemctl"
              "--user"
              "start"
              "tablet-mode"
            ];
            tablet-mode-off.action.spawn = [
              "systemctl"
              "--user"
              "stop"
              "tablet-mode"
            ];
          };
        };
      };
      systemd.user.services.tablet-mode = {
        Unit = {
          Description = "Tablet mode: auto-rotation, bigger scale, on-screen keyboard";
          PartOf = [ config.wayland.systemd.target ];
          After = [ config.wayland.systemd.target ];
          Wants = [ "wvkbd.service" ];
        };
        Service = {
          ExecStartPre = "${niri} msg output ${output} scale 1.25";
          ExecStart = rotate;
          ExecStopPost = [
            "${niri} msg output ${output} transform normal"
            "${niri} msg output ${output} scale ${toString config.services.kanshi.builtinDisplay.scale}"
          ];
        };
      };
      # SIGRTMIN toggles it; heights are logical px, the defaults (250 portrait,
      # 120 landscape) are sized for phones
      systemd.user.services.wvkbd = {
        Unit = {
          Description = "On-screen keyboard";
          PartOf = [ "tablet-mode.service" ];
        };
        Service.ExecStart =
          let
            layers = "full,special";
          in
          "${pkgs.wvkbd}/bin/wvkbd-mobintl -H 450 -L 380 -l ${layers} --landscape-layers ${layers}";
      };
    };
}
