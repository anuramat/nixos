{ pkgs, lib, ... }:
let
  inherit (lib) getExe;
  toList = str: lib.splitString " " str;
in
{
  # TODO make a builder and reuse in sway
  programs.waybar = {
    enable = true;
    # TODO MemoryMax="500M"
    systemd.enable = true;
    style = # css
      ''
        #waybar > box {
          padding: 0px 10px;
        }
      '';
    settings =
      let
        main = {
          mode = "dock";
          position = "top";
          ipc = true;
          spacing = 5;
          tray.spacing = 10;
          clock = {
            format = "{:%Y-%m-%d %a %H:%M:%S}";
            interval = 1;
          };
        };
        modules = {
          modules-left = [
            "pulseaudio"
            "backlight"
            "idle_inhibitor"
            "niri/language"
            "mpris"
          ];
          modules-center = [
            "custom/rec"
            "niri/workspaces"
          ];
          modules-right = [
            "tray"
            "disk"
            "battery"
            "clock"
          ];
        };
        indicators = {
          "custom/rec" = {
            exec = "${pkgs.procps}/bin/pgrep -x wf-recorder >/dev/null && echo '⏺\'";
            # TODO red color
            interval = 1;
            tooltip = false;
            on-click =
              let
                pkill = "${pkgs.procps}/bin/pkill";
              in
              "${pkill} -INT -x wf-recorder";
          };
          mpris = {
            dynamic-len = 1;
            dynamic-priority = [
              "length"
              "position"
              "album"
            ];
            format = "{player_icon}  {status_icon} {dynamic}";
            interval = 1;
            max-length = 999;
            # player = "spotify";
            player-icons = {
              default = "";
              spotify = "󰓇";
            };
            status-icons = {
              paused = "󰏤";
              playing = "󰐊";
            };
          };
          idle_inhibitor = {
            format = "{icon}";
            format-icons = {
              activated = " ";
              deactivated = " ";
            };
          };
        };
        controls = {
          pulseaudio = {
            format = "{volume}% {icon}  {format_source}";
            format-bluetooth = "{volume}% {icon}   {format_source}";
            format-bluetooth-muted = "{volume}% 󰖁 {icon}   {format_source}";
            format-icons = {
              car = "";
              default = [
                "󰕿"
                "󰖀"
                "󰕾"
              ];
              hands-free = "󰋎";
              headphone = "";
              headset = "󰋎";
              phone = "";
              portable = "";
            };
            format-muted = "{volume}% 󰖁  {format_source}";
            format-source = "{volume}% 󰍬";
            format-source-muted = "{volume}% 󰍭";
            on-click = "${getExe pkgs.pavucontrol}";
            on-click-middle = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
            on-click-right = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
          };
          backlight = {
            format = "{percent}% {icon}";
            format-icons = toList "        ";
          };
        };
        metrics = {
          battery = {
            format = "{capacity}% {icon}";
            format-charging = "{capacity}% 󰂄";
            format-plugged = "{capacity}% 󰚥";
            format-icons = toList "󰂎 󰁺 󰁻 󰁼 󰁽 󰁾 󰁿 󰂀 󰂁 󰂂 󰁹";
            interval = 1;
            states = {
              critical = 15;
              warning = 30;
            };
          };
          disk = {
            format = "{percentage_used}% ";
            path = "/";
          };
        };
        niri = { };
        sway = {
          "sway/scratchpad" = {
            format = "{icon} {count}";
            format-icons = [
              ""
              ""
            ];
            show-empty = false;
          };
          "sway/workspaces" = {
            disable-scroll = true;
            format = "{name}";
          };
        };
      in
      [
        (main // modules // indicators // sway // controls // metrics)
      ];
  };
}
