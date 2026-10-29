# Saving noctalia GUI changes: they are written as overrides to
# $XDG_STATE_HOME/noctalia/settings.toml, on top of programs.noctalia.settings.
# - Ignore the [wallpaper.*] entries (wallpaper.default, wallpaper.last):
#   noctalia writes them on its own, they are not user choices.
# - Desktop and lockscreen widgets, geometry included, go here (the fleet
#   monitor's to fleet-monitor/), without `output`, under the stable ids
#   declared in Nix rather than noctalia's generated desktop-widget-N and
#   lockscreen-login-box@CONNECTOR ids: widget-relative-position.patch makes cx
#   and cy fractions of the output's logical size, so the same placement fits
#   every host and survives f12's tablet-mode rotation.
# - The login box is the one widget that needs `output`, set per host in
#   nixos-configurations/$HOST/default.nix: noctalia replaces one without it
#   with a default box.
# - The fleet monitor must not get box_width or box_height: a box scales the
#   content to fit it, so its size goes to settings.width and settings.height,
#   also fractions of the output's logical size.
# - Any edit in noctalia's widget editor writes every widget's placement to the
#   state file, shadowing the Nix values, so once they are saved here, delete
#   the [desktop_widgets] and [lockscreen_widgets] sections from the state file.
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
    # upstream's secret agent leaves NM's background requests for a new wifi
    # key to an unseen prompt, so NM gives up on the network until a manual
    # reconnect
    # upstream never advances lockscreen widgets' animations, so the mouse
    # wheel can't scroll the fleet monitor there
    # upstream has right-click only on plugin buttons, so the fleet monitor
    # couldn't toggle a section on a right-click
    # upstream labels wifi networks by SSID; this shows the saved NM profile's
    # name instead, so a network can be renamed with `nmcli`
    # upstream always shows the lockscreen login box, which hides the widgets
    # behind it and takes their input; this hides it while the password is empty
    # upstream places widgets at a fixed cx/cy in logical px, which drift off
    # screen when the output's logical size changes (f12's tablet mode rotates
    # and rescales it); this makes cx/cy fractions of the output's size, and
    # lets plugin desktop widgets look up their output, to size themselves
    # upstream runs plugin callbacks (async commands, streams, ...) with an
    # empty context, so that `desktopWidget.outputName()` reads nil inside
    # them; this keeps the last call's
    package = pkgs.noctalia.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [
        ./pam-setcred.patch
        ./secret-agent-saved-psk.patch
        ./lockscreen-widget-animations.patch
        ./ui-right-click.patch
        ./wifi-profile-names.patch
        ./lockscreen-login-hide-empty.patch
        ./widget-relative-position.patch
        ./plugin-callback-context.patch
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
        # centered; noctalia replaces a login box without `output` with a
        # default one, so its output is set per host
        widget.login = {
          type = "login_box";
          cx = 0.5;
          cy = 0.5;
          settings = {
            layout = "compact";
            show_login_button = false;
            show_unlock_hint = false;
          };
        };
      };
      hooks.session_locked = [ (lib.getExe config.lib.keyring.lock) ];

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
