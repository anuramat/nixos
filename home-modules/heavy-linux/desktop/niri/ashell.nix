{ config, ... }:
{
  # waybar replacement candidate -- module ships with home-manager, package from nixpkgs
  programs.ashell = {
    enable = false;
    systemd.enable = true;

    settings = {
      position = "Top";
      layer = "Top";

      modules = {
        left = [
          "KeyboardLayout"
          "MediaPlayer"
        ];
        center = [ "WindowTitle" ];
        right = [
          "Tray"
          "Settings"
          "Clock"
        ];
      };

      # colors/opacity come from stylix; Islands is the default, Solid is the
      # flat full-width look waybar had
      appearance.style = "Solid";

      # NOTE keys are xkb layout descriptions, not codes
      keyboard_layout.labels = {
        "English (US)" = "EN";
        "Russian" = "RU";
      };

      window_title = {
        mode = "Title";
        truncate_title_after_length = 80;
      };

      clock.format = "%F %A %T"; # %T is detected as a seconds specifier -> 1s tick

      media_player = {
        indicator_format = "IconAndTitle";
        max_title_length = 60;
      };

      # battery, volume and the idle inhibitor are indicators rendered by the
      # Settings module rather than standalone modules; clicking one opens the
      # control popup
      settings = {
        indicators = [
          "IdleInhibitor"
          "Audio"
          "Battery"
        ];
        battery_format = "IconAndPercentage";
        lock_cmd = config.lib.lockscreen.lock;
      };
    };
  };
}
