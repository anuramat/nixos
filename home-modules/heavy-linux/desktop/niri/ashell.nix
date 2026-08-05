{
  config,
  lib,
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

  programs.ashell = {
    enable = true;
    systemd.enable = true;

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
          "Settings"
          "Clock"
        ];
      };

      CustomModule = [
        {
          name = "rec";
          type = "Text";
          listen_cmd = "${recIndicator}";
        }
      ];

      # colors/opacity come from stylix; Islands is the default, Solid is the
      # flat full-width look waybar had. Icons are hardcoded to Symbols Nerd
      # Font regardless of font_name -- nerd-fonts.symbols-only covers that.
      appearance = {
        style = "Islands";
        font_name = config.stylix.fonts.${config.stylix.targets.waybar.font}.name;
      };

      keyboard_layout.labels = {
        "English (US)" = "EN";
        "Russian" = "RU";
      };

      clock.format = "%F %A %T"; # %T is detected as a seconds specifier -> 1s tick

      media_player = {
        indicator_format = "IconAndTitle";
        # max_title_length = 60;
      };

      settings = {
        indicators = [
          "IdleInhibitor"
          "Audio"
          "Battery"
        ];
        battery_format = "IconAndPercentage";
        lock_cmd = config.lib.lockscreen.lock;
        logout_cmd = "${lib.getExe pkgs.niri} msg action quit --skip-confirmation";
        shutdown_cmd = "${pkgs.systemd}/bin/systemctl poweroff";
        reboot_cmd = "${pkgs.systemd}/bin/systemctl reboot";
        suspend_cmd = "${pkgs.systemd}/bin/systemctl suspend";
        hibernate_cmd = "${pkgs.systemd}/bin/systemctl hibernate";
      };
    };
  };
}
