{ inputs, ... }:
{
  # waybar replacement candidate -- full shell, not just a bar
  imports = [ inputs.noctalia.homeModules.default ];

  programs.noctalia = {
    enable = false;
    systemd.enable = true;

    # NOTE this is the base layer only -- the settings menu writes overrides to
    # $XDG_STATE_HOME/noctalia/settings.toml, which silently shadow these
    settings = {
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
          "volume"
          "battery"
          "clock"
        ];
      };

      shell = {
        font_family = "sans-serif";
        time_format = "{:%F %A %T}";
        date_format = "%A, %F";
        telemetry_enabled = false;
        offline_mode = true;
      };

      # noctalia bundles a notification daemon, launcher, lockscreen and
      # wallpaper manager -- leave them off, they overlap with the existing setup
      notification.enable_daemon = false;
      lockscreen.enabled = false;
      dock.enabled = false;
      desktop_widgets.enabled = false;
    };
  };
}
