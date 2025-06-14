{
  programs.waybar = {
    enable = true;
    systemd.enable = false;
    style = # css
      ''
        #waybar > box {
          padding: 0px 10px;
        }
      '';
    settings = [
      # TODO sort fields
      {
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
        "battery#internal" = {
          bat = "BAT0";
          format = "I:{capacity}%";
        };
        "battery#external" = {
          bat = "BAT1";
          format = "E:{capacity}%";
        };
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
        bluetooth = {
          format = "{status} ";
          on-click = "blueman-manager";
        };
        clock = {
          format = "{:%Y-%m-%d %H:%M:%S}";
          interval = 1;
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };
        cpu = {
          format = "{usage}% ";
          tooltip = false;
        };
        disk = {
          format = "{percentage_used}% ";
          path = "/";
        };
        idle_inhibitor = {
          format = "{icon}";
          format-icons = {
            activated = " ";
            deactivated = " ";
          };
        };
        ipc = true;
        memory = {
          format = "{}% ";
        };
        mode = "overlay";
        modules-center = [
          "sway/workspaces"
          "sway/scratchpad"
        ];
        modules-left = [
          "pulseaudio"
          "backlight"
          "idle_inhibitor"
          "mpris"
        ];
        spacing = 5;
        tray = {
          spacing = 10;
        };
        modules-right = [
          "sway/window"
          "tray"
          "battery"
          "battery#internal"
          "battery#external"
          "disk"
          "sway/language"
          "clock"
        ];
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
        position = "top";
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
        "sway/language" = {
          tooltip-format = "{flag} {long} {variant}";
        };
        "sway/scratchpad" = {
          format = "{icon} {count}";
          format-icons = [
            ""
            ""
          ];
          show-empty = false;
          tooltip = true;
          tooltip-format = "{app}: {title}";
        };
        "sway/window" = {
          icon = true;
        };
        "sway/workspaces" = {
          disable-scroll = true;
          format = "{name}";
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
      }
    ];
  };
}
