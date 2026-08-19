{
  lib,
  config,
  inputs,
  ...
}:
let
  c = config.lib.stylix.colors.withHashtag;
in
{
  # full shell: replaces ashell (bar/OSD/notifications/settings), swaylock,
  # swayidle, wl-clip-persist, and the bemenu drun launcher
  imports = [ inputs.noctalia.homeModules.default ];

  programs.niri.settings.binds."Mod+S".action.spawn = [
    (lib.getExe config.programs.noctalia.package)
    "msg"
    "bar-toggle"
  ];

  programs.noctalia = {
    enable = true;
    systemd.enable = true;

    # NOTE this is the base layer only -- the settings GUI writes overrides
    # that silently shadow these
    settings = {
      shell = {
        font_family = config.stylix.fonts.monospace.name;
        time_format = "{:%F %A %T}"; # %T is a seconds specifier -> 1s tick
        date_format = "%A, %F";
        telemetry_enabled = false;
        offline_mode = true;
        keyboard_layout.custom_labels = {
          "English (US)" = "EN";
          "Russian" = "RU";
        };
      };

      bar.main = {
        position = "top";
        thickness = 34;
        radius = 0;
        margin_ends = 0;
        margin_edge = 0;
        reserve_space = true;

        start = [
          "caffeine"
          "keyboard_layout"
          "media"
        ];
        center = [ "active_window" ];
        end = [
          "tray"
          "notifications"
          "volume"
          "battery"
          "clock"
          "control-center"
          "session"
        ];
      };

      theme = {
        mode = "dark";
        source = "custom";
        custom_palette = "stylix";
      };

      # keep niri's stylix background-color instead
      wallpaper.enabled = false;

      # replaces swayidle; suspend/logind lock integration is built in
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

      lockscreen.enabled = true;
      hooks.session_locked = lib.getExe config.lib.keyring.lock;

      dock.enabled = false;
      desktop_widgets.enabled = false;
    };

    # stylix has no v5 noctalia target on release-26.05 (only on master, which
    # is incompatible with stable nixpkgs); role mapping mirrors that target
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
          green = c.base0B;
          yellow = c.base0A;
          blue = c.base0D;
          magenta = c.base0E;
          cyan = c.base0C;
          white = c.base05;
        };
        bright = {
          black = c.base03;
          red = c.base08;
          green = c.base0B;
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
