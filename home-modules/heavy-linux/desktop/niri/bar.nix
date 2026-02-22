{ pkgs, lib, ... }:
let
  inherit (lib) getExe;
  toList = str: lib.splitString " " str;
  #

  niriWindowsModule = pkgs.fetchurl {
    url = "https://github.com/calico32/waybar-niri-windows/releases/download/v2.3.0/waybar-niri-windows.so";
    hash = "sha256-sUWndS52KnAKBemkPdDM1hprq97LKsfraY0oXJE1Rnw=";
  };

in
{
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
          layer = "top";
          exclusive = true;
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
            "niri/workspaces"
            "mpris"
          ];
          modules-center = [
            # "custom/rec"
            "cffi/niri-windows"
          ];
          modules-right = [
            "tray"
            "niri/language"
            "pulseaudio"
            # "backlight"
            "battery"
            "clock"
            "idle_inhibitor"
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
              activated = "";
              deactivated = "";
            };
          };
        };
        controls = {
          pulseaudio = {
            # NOTE add "  {format_source}" to show source volume
            format = "{volume}% {icon}";
            format-muted = "{volume}% 󰖁";
            format-bluetooth = "{volume}% {icon} ";
            format-bluetooth-muted = "{volume}% 󰖁 {icon} ";
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
        niri = {
          "niri/language" = {
            format = "{short}";
          };
          "cffi/niri-windows" = {
            module_path = niriWindowsModule;
            options = {
              show-floating = "never";
              rules = [
                {
                  app-id = "foot";
                  class = "foot";
                  icon = "";
                }
              ];
            };
          };
        };
      in
      # TODO unfuck this
      [
        (main // modules // indicators // controls // metrics // niri)
      ];
  };
  systemd.user.services.waybar = {
    Service = {
      MemoryMax = "500M";
      OOMPolicy = "kill";
    };
  };
}
