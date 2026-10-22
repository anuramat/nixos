# touchscreen gestures, the `above-lock` layer rule and edge swipes while
# locked come from the patches in overlays/niri. tablet mode (screen folded back): a user service, started and
# stopped by niri's switch events, rotates the panel with the accelerometer,
# bumps its scale for fingers, and starts a hidden on-screen keyboard, which a
# swipe from the bottom edge toggles, also on the lock screen. the power key
# toggles the EC's tablet mode detection off ("laptop") and back on ("auto"),
# since "auto" sometimes leaves the keyboard disabled
{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:
let
  inherit (inputs.self.consts.user) username;
  output = "eDP-1";
  sudo = "${config.security.wrapperDir}/sudo";
  # the EC override can't be read back, so the state lives in /run
  # TODO if a firmware update (past BIOS 03.04) doesn't fix the stuck keyboard:
  # the keyboard block lives in the EC, independent of the SW_TABLET_MODE gpio
  # that drives tablet-mode.service, so an untested automatic fix is pulsing
  # `--tablet-mode laptop` then `auto` from the service's ExecStopPost (maybe
  # with a delay in between); `laptop` alone would kill the switch events
  toggle = pkgs.writeShellScript "tablet-mode-toggle" ''
    f=/run/tablet-mode-laptop
    if [[ -e $f ]]; then rm $f; m=auto; else touch $f; m=laptop; fi
    ${lib.getExe pkgs.framework-tool} --tablet-mode $m >/dev/null && echo $m
  '';
in
{
  services.logind.settings.Login.HandlePowerKey = lib.mkForce "ignore";
  security.sudo.extraRules = [
    {
      users = [ username ];
      commands = [
        {
          command = "${toggle}";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
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
        # 3 fingers drag the view and the workspaces; the patch's defaults also
        # bind a 3-finger tap to maximize-column. 4-finger flicks and taps fire
        # once, on lift
        extraConfig = ''
          layer-rule {
              match namespace="^wvkbd$"
              above-lock true
          }
          gestures {
              touchscreen-swipe {
                  tap-more { fullscreen-window; }
                  swipe-more-down { spawn "${lib.getExe config.programs.noctalia.package}" "msg" "panel-toggle" "launcher"; }
                  swipe-more-up { close-window; }
              }
              touchscreen-edge-swipe {
                  top { toggle-overview; }
                  bottom allow-when-locked=true { spawn "${pkgs.systemd}/bin/systemctl" "--user" "kill" "-s" "RTMIN" "wvkbd"; }
              }
          }
        '';
        settings = {
          input = {
            touch.map-to-output = output;
            power-key-handling.enable = false;
          };
          # also on the lock screen, where a disabled keyboard can't type the password
          binds."XF86PowerOff" = {
            allow-when-locked = true;
            action.spawn-sh = ''${lib.getExe' pkgs.libnotify "notify-send"} "Tablet mode" "$(${sudo} ${toggle})"'';
          };
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
        Service.ExecStart = "${pkgs.wvkbd}/bin/wvkbd-deskintl --hidden -H 450 -L 380 -l full --landscape-layers full";
      };
    };
}
