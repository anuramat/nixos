{
  programs.waybar = {
    enable = true;
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
            on-click = "pavucontrol";
            on-click-middle = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
            on-click-right = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
          };
          backlight = {
            format = "{percent}% {icon}";
            format-icons = [
              ""
              ""
              ""
              ""
              ""
              ""
              ""
              ""
              ""
            ];
          };
        };
        metrics = {
          battery = {
            format = "{capacity}% {icon}";
            format-alt = "{time} {icon}";
            format-charging = "{capacity}% 󰂄";
            format-icons = [
              "󰂎"
              "󰁺"
              "󰁻"
              "󰁼"
              "󰁽"
              "󰁾"
              "󰁿"
              "󰂀"
              "󰂁"
              "󰂂"
              "󰁹"
            ];
            format-plugged = "{capacity}% 󰚥";
            interval = 1;
            states = {
              critical = 15;
              warning = 30;
            };
          };
          cpu.format = "{usage}% ";
          memory.format = "{}% ";
          disk = {
            format = "{percentage_used}% ";
            path = "/";
          };
          temperature = {
            critical-threshold = 80;
            format = "{temperatureC}°C {icon}";
            format-icons = [
              "󱃃"
              "󰔏"
              "󱃂"
            ];
          };
        };
        modules = {
          modules-left = [
            "pulseaudio"
            "backlight"
            "idle_inhibitor"
            "mpris"
          ];
          modules-center = [
            "sway/workspaces"
            "sway/scratchpad"
          ];
          modules-right = [
            "sway/window"
            "tray"
            "battery"
            "disk"
            "sway/language"
            "clock"
          ];
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
          "sway/window" = {
            icon = true;
          };
          "sway/workspaces" = {
            disable-scroll = true;
            format = "{name}";
          };
        };
      in
      [
        (main // modules // sway // controls // metrics)
      ];
  };
}
