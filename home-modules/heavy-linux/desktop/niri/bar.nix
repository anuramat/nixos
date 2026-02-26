{ pkgs, lib, ... }:
let
  toList = str: lib.splitString " " str;
  niriWindowsModule = pkgs.fetchurl {
    url = "https://github.com/calico32/waybar-niri-windows/releases/download/v2.3.0/waybar-niri-windows.so";
    hash = "sha256-sUWndS52KnAKBemkPdDM1hprq97LKsfraY0oXJE1Rnw=";
  };
in
{
  systemd.user.services.waybar.Service = {
    Restart = lib.mkForce "always";
    RestartSec = 10;
    # in case it leaks
    MemoryMax = "500M";
    OOMPolicy = "kill";
  };
  programs.waybar = {
    enable = true;
    systemd.enable = true;

    style = # css
      ''
        #waybar > box {
          padding: 5px 10px;
        }
        .cffi-niri-windows > * {
          min-height: 30px;
        }
        #custom-rec {
          color: @base08;
        }
        #idle_inhibitor.activated {
          color: @base08;
        }
        #idle_inhibitor.deactivated {
          color: @base03;
        }
      '';

    settings = [
      {

        layer = "top";
        exclusive = true;
        position = "top";
        spacing = 10;
        tray.spacing = 10;

        modules-left = [
          "idle_inhibitor"
          "niri/language"
          "mpris"
        ];

        modules-center = [
          "custom/rec"
          "cffi/niri-windows"
        ];

        modules-right = [
          "tray"
          "pulseaudio"
          "battery"
          "clock"
        ];

        clock = {
          format = "{:%F %A %T}";
          interval = 1;
        };

        "custom/rec" = {
          exec = "${pkgs.procps}/bin/pgrep -x gpu-screen-reco >/dev/null && echo '⏺\'";
          # TODO update with signal on hotkey
          interval = 1;
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

        pulseaudio = {
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
          # NOTE add "  {format_source}" to formats above to show source volume:
          format-source = "{volume}% 󰍬";
          format-source-muted = "{volume}% 󰍭";
        };

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

      }
    ];
  };
}
