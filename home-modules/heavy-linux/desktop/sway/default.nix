{ config, ... }:
{
  imports = [
    ./inputs.nix
    ./keys
    ./autologin.nix
    ./outputs.nix
    ./waybar.nix
    ./swayidle.nix
  ];
  wayland.systemd.target =
    let
      name = "sway-session";
    in
    if config.systemd.user.targets ? ${name} then
      "${name}.target"
    else
      throw "target ${name} not found";
  wayland.windowManager.sway =
    let
      border = 3;
    in
    {
      enable = true;
      checkConfig = true;
      wrapperFeatures.gtk = true;
      systemd = {
        xdgAutostart = true;
        variables =
          let
            defaults = [
              "DISPLAY"
              "WAYLAND_DISPLAY"
              "SWAYSOCK"
              "XDG_CURRENT_DESKTOP"
              "XDG_SESSION_TYPE"
              "NIXOS_OZONE_WL"
              "XCURSOR_THEME"
              "XCURSOR_SIZE"
            ];
          in
          defaults
          ++ [
            "DBUS_SESSION_BUS_ADDRESS" # for proton-bridge
          ];
      };
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
            # breaks games -- mouse movement gets disabled as well when "typing"
            # hide_cursor = "when-typing enable";
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
            { app_id = "Proton Pass"; }
            { app_id = "udiskie"; }
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
