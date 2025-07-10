{ pkgs, lib, ... }:
let
  inherit (lib) getExe;
  toList = sep: str: lib.splitString sep str |> lib.filter (v: v != "");
in
{
  programs.waybar = {
    enable = true;
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
            format = "{:%Y-%m-%d %H:%M:%S}";
            interval = 1;
          };
        };
        modules = {
          modules-left = [
            "pulseaudio"
            "backlight"
            "idle_inhibitor"
            "sway/language"
            "mpris"
          ];
          modules-center = [
            "sway/workspaces"
            "sway/scratchpad"
          ];
          modules-right = [
            "tray"
            "disk"
            "battery"
            "clock"
          ];
        };
        controls = {
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
            player = "spotify";
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
            format-icons = toList " " "        ";
          };
        };
        metrics = {
          battery = {
            format = "{capacity}% {icon}";
            format-charging = "{capacity}% 󰂄";
            format-plugged = "{capacity}% 󰚥";
            format-icons = toList "" "󰂎󰁺󰁻󰁼󰁽󰁾󰁿󰂀󰂁󰂂󰁹";
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
        (main // modules // controls // metrics // sway)
      ];
  };
}
