{
  imports = [
    ./input.nix
    ./autostart.nix
    ./keys
    ./autologin.nix
    ./output.nix
  ];
  wayland.windowManager.sway =
    let
      border = 3;
    in
    {
      enable = true;
      checkConfig = true;
      wrapperFeatures.gtk = true;
      config = {
        bars = [ ]; # handled by a systemd service
        focus = {
          followMouse = "no";
          wrapping = "no";
          mouseWarping = "container";
          newWindow = "none";
        };
        seat = {
          "*" = {
            hide_cursor = "when-typing enable";
          };
        };
        window = {
          titlebar = false;
          inherit border;
        };
        floating = {
          inherit border;
          titlebar = true;
          criteria = [
            { app_id = "xdg-desktop-portal-gtk"; }
            { app_id = "nm-connection-editor"; }
            { app_id = "keymapp"; }
            { app_id = "openrgb"; }
            { app_id = "foot-float"; }
            { app_id = "ghostty.float"; }
            { app_id = "Proton Pass"; }
          ];
        };
      };
      # TODO relative size
      extraConfig = # sway
        ''
          title_align center
          for_window [shell="xwayland"] title_format "%title [XWayland]"
          floating_maximum_size 1420 x 980
          floating_minimum_size 600 x 480
        '';
    };
  # TODO do I need to include /etc/sway/config.d/*
}
