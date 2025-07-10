{
  imports = [
    ./inputs.nix
    ./keys
    ./autologin.nix
    ./outputs.nix
    ./waybar.nix
  ];
  wayland.windowManager.sway =
    let
      border = 3;
    in
    {
      enable = true;
      checkConfig = true;
      wrapperFeatures.gtk = true;
      systemd.xdgAutostart = true;
      config = {
        bars = [ ];
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
            { app_id = "nm-connection-editor"; }
            { app_id = "keymapp"; }
            { app_id = "openrgb"; }
            { app_id = "foot-float"; }
            { app_id = "Proton Pass"; }
          ];
        };
      };
      extraConfig = # sway
        ''
          title_align center
          for_window [shell="xwayland"] title_format "%title [XWayland]"
        '';
    };
}
