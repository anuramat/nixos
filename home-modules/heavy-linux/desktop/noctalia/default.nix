{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
let
  c = config.lib.stylix.colors.withHashtag;
in
{
  imports = [
    inputs.noctalia.homeModules.default
    ./fleet-monitor
  ];

  programs.noctalia = {
    enable = true;
    systemd.enable = true;

    # upstream never runs the credential stack, so pam_gnupg can't preset the
    # gpg passphrase on unlock; see the patch and nixos-modules/local/default.nix
    # upstream's fileInfo mtime jitters between calls, which the fleet monitor
    # compares to detect a new uc3 snapshot
    package = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [
        ./pam-setcred.patch
        ./fileinfo-mtime.patch
      ];
    });

    settings = {
      shell = {
        font_family = config.stylix.fonts.monospace.name;
        time_format = "{:%F %A %T}";
        date_format = "%A, %F";
        telemetry_enabled = false;
        offline_mode = false;
        niri_overview_type_to_launch_enabled = true;
        keyboard_layout.custom_labels = {
          "English (US)" = "EN";
          "Russian" = "RU";
        };
        launcher = {
          categories = false;
          compact = true;
        };
      };

      location.address = inputs.self.consts.user.location;

      bar.main = {
        position = "top";
        thickness = 40;
        scale = 1.15;
        widget_spacing = 16;
        radius = 0;
        margin_ends = 0;
        margin_edge = 0;
        reserve_space = false;
        auto_hide = false;
        smart_auto_hide = true;
        layer = "overlay";

        start = [ "active_window" ];
        center = [ ];
        end = [
          "tray"
          "network"
          "battery"
          "clock"
        ];
      };

      widget = {
        clock.format = "{:%Y-%m-%d %H:%M:%S}";
        notifications.hide_when_no_unread = true;
        tray.drawer = true;
      };

      theme = {
        mode = "dark";
        source = "custom";
        custom_palette = "stylix";
      };

      wallpaper.enabled = false;

      idle.behavior = {
        lock = {
          enabled = true;
          timeout = 300;
          action = "lock";
        };
        screen-off = {
          enabled = true;
          timeout = 600;
          action = "screen_off";
        };
      };

      lockscreen = {
        enabled = true;
        blurred_desktop = true;
      };

      lockscreen_widgets = {
        enabled = true;
        # geometry is set per host, like the fleet monitor's; noctalia replaces
        # a login box without `output` with a default one, so its output is set
        # per host too
        widget.login = {
          type = "login_box";
          settings = {
            layout = "compact";
            show_login_button = false;
            show_unlock_hint = false;
          };
        };
      };
      hooks.session_locked = lib.getExe config.lib.keyring.lock;

      dock = {
        enabled = true;
        reserve_space = false;
        smart_auto_hide = true;
      };

      control_center = {
        width = 1000;
        shortcuts = map (type: { inherit type; }) [
          "notification"
          "caffeine"
          "nightlight"
          "clipboard"
          "bluetooth"
          "wifi"
        ];
      };
      notification.history_retention_hours = 24;
      nightlight.enabled = true;

      # disable toast on mic/camera/screen capture
      osd.kinds.privacy = false;

      keybinds.cancel = [
        "Escape"
        "Ctrl+c"
      ];
    };

    # NOTE stylix has no noctalia target on release-26.05, drop this once it does
    customPalettes.stylix.dark = {
      primary = c.base0D;
      onPrimary = c.base00;
      secondary = c.base0E;
      onSecondary = c.base00;
      tertiary = c.base0C;
      onTertiary = c.base00;
      error = c.base08;
      onError = c.base00;
      surface = c.base00;
      onSurface = c.base05;
      surfaceVariant = c.base01;
      onSurfaceVariant = c.base04;
      outline = c.base03;
      shadow = c.base00;
      hover = c.base0C;
      onHover = c.base00;
      terminal = {
        foreground = c.base05;
        background = c.base00;
        cursor = c.base05;
        cursorText = c.base00;
        selectionFg = c.base05;
        selectionBg = c.base02;
        normal = {
          black = c.base00;
          red = c.base08;
          yellow = c.base0A;
          blue = c.base0D;
          magenta = c.base0E;
          cyan = c.base0C;
          white = c.base05;
        };
        bright = {
          black = c.base03;
          red = c.base08;
          yellow = c.base0A;
          blue = c.base0D;
          magenta = c.base0E;
          cyan = c.base0C;
          white = c.base07;
        };
      };
    };
  };
}
