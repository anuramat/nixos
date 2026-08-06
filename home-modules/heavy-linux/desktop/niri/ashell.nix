{
  config,
  pkgs,
  ...
}:
let
  recIndicator = pkgs.writeShellScript "ashell-rec" ''
    while :; do
      if ${pkgs.procps}/bin/pgrep -x gpu-screen-reco >/dev/null; then
        echo '{"alt":"rec","text":"⏺"}'
      else
        echo '{"alt":"","text":""}'
      fi
      ${pkgs.coreutils}/bin/sleep 1
    done
  '';
in
{
  systemd.user.services.ashell = {
    Unit.PartOf = [ config.wayland.systemd.target ]; # module only sets After/WantedBy
  };

  programs.niri.settings.binds."Mod+S".action.spawn = [
    "${config.programs.ashell.package}/bin/ashell"
    "msg"
    "toggle-visibility"
  ];

  programs.ashell = {
    enable = true;
    systemd.enable = true;
    # 0.9.0 with the hide-empty patch comes from the overlay

    settings = {
      position = "Top";
      layer = "Top";

      modules = {
        left = [
          "KeyboardLayout"
          "MediaPlayer"
        ];
        center = [
          "rec"
          "WindowTitle"
        ];
        right = [
          "Tray"
          "Notifications"
          "Settings"
          "Tempo"
        ];
      };

      CustomModule = [
        {
          name = "rec";
          type = "Text";
          listen_cmd = "${recIndicator}";
        }
      ];

      appearance = {
        font_name = config.stylix.fonts.monospace.name;
        style = "Islands";
        warning_color = config.lib.stylix.colors.withHashtag.base0A;
      };

      keyboard_layout.labels = {
        "English (US)" = "EN";
        "Russian" = "RU";
      };

      window_title = {
        mode = "Title";
        truncate_title_after_length = 80;
      };

      tempo = {
        clock_format = "%F %A %T"; # %T is a seconds specifier -> 1s tick
        weather_indicator = "None"; # otherwise it geolocates and polls a weather api
      };

      media_player = {
        indicator_format = "IconAndTitle";
        max_title_length = 60;
      };

      notifications = {
        grouped = true;
        toast_position = "top_right";
        toast_timeout = 10000;
      };

      osd = {
        enabled = true;
        show_volume_percentage = true;
        show_brightness_percentage = true;
      };

      settings = {
        indicators = [
          "IdleInhibitor"
          "Audio"
          "Battery"
        ];
        battery_format = "IconAndPercentage";
        lock_cmd = config.lib.lockscreen.lock;
        logout_cmd = "${pkgs.niri}/bin/niri msg action quit --skip-confirmation";
        shutdown_cmd = "${pkgs.systemd}/bin/systemctl poweroff";
        reboot_cmd = "${pkgs.systemd}/bin/systemctl reboot";
        suspend_cmd = "${pkgs.systemd}/bin/systemctl suspend";
        hibernate_cmd = "${pkgs.systemd}/bin/systemctl hibernate";
        bluetooth_more_cmd = "${pkgs.blueman}/bin/blueman-manager";
      };
    };
  };
}
