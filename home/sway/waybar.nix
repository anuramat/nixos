{
  programs.waybar = {
    enable = true;
    systemd.enable = false;
    style = ./waybar/style.css;
    settings = [
      {
        mode = "overlay";
        margin = 0;
        ipc = true;
        position = "bottom";
        spacing = 5;
        modules-left = [
          "pulseaudio"
          "backlight"
          "idle_inhibitor"
          "mpris"
        ];
        modules-center = [
          "sway/mode"
          "sway/workspaces"
          "sway/scratchpad"
          "sway/mode"
        ];
        modules-right = [
          "sway/window"
          "tray"
          "battery"
          "sway/language"
          "clock"
        ];
        "sway/window" = {
          icon = true;
        };
        "sway/workspaces" = {
          disable-scroll = true;
          format = "{name}";
        };
        "sway/mode" = {
          format = "{}";
        };
        "sway/scratchpad" = {
          format = "{icon} {count}";
          show-empty = false;
          format-icons = [
            ""
            ""
          ];
          tooltip = true;
          tooltip-format = "{app}: {title}";
        };
        idle_inhibitor = {
          format = "{icon}";
          format-icons = {
            activated = "";
            deactivated = "";
          };
        };
        clock = {
          format = "{:%Y-%m-%d %H:%M:%S}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
          interval = 1;
        };
        "sway/language" = {
          tooltip-format = "{flag} {long} {variant}";
        };
        tray = {
          spacing = 10;
        };
        cpu = {
          format = "{usage}% ";
          tooltip = false;
        };
        memory = {
          format = "{}% ";
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
        battery = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{capacity}% {icon}";
          format-charging = "{capacity}% 󰂄";
          format-plugged = "{capacity}% 󰚥";
          format-alt = "{time} {icon}";
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
          interval = 1;
        };
        "battery#internal" = {
          bat = "BAT0";
        };
        "battery#external" = {
          bat = "BAT1";
        };
        pulseaudio = {
          format = "{volume}% {icon}  {format_source}";
          format-bluetooth = "{volume}% {icon}   {format_source}";
          format-bluetooth-muted = "{volume}% 󰖁 {icon}   {format_source}";
          format-muted = "{volume}% 󰖁  {format_source}";
          format-source = "{volume}% 󰍬";
          format-source-muted = "{volume}% 󰍭";
          format-icons = {
            headphone = "";
            hands-free = "󰋎";
            headset = "󰋎";
            phone = "";
            portable = "";
            car = "";
            default = [
              "󰕿"
              "󰖀"
              "󰕾"
            ];
          };
          on-click = "pavucontrol";
          on-click-right = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
          on-click-middle = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        };
        mpris = {
          interval = 1;
          format = "{player_icon}  {status_icon} {dynamic}";
          player = "spotify";
          player-icons = {
            default = "";
            spotify = "󰓇";
          };
          dynamic-priority = [
            "length"
            "position"
            "album"
          ];
          status-icons = {
            paused = "󰏤";
            playing = "󰐊";
          };
          dynamic-len = 1;
          max-length = 999;
        };
        disk = {
          path = "/";
          format = "{percentage_used}% ";
        };
        bluetooth = {
          format = "{status} ";
          on-click = "blueman-manager";
        };
      }
    ];
  };
}
