{ pkgs, osConfig, ... }:
{
  services = {
    blueman-applet.enable = osConfig.services.blueman.enable;
    avizo = {
      enable = true;
      settings = {
        default = {
          time = 0.5;
        };
      };

    };
    udiskie = {
      enable = true;
      notify = true;
      tray = "auto";
      automount = true;
    };
  };
  services.network-manager-applet.enable = true;
  imports = [
    ./swayidle.nix
    ./keys.nix
    ./swaylock.nix
    ./input.nix
    ./workspace.nix
    ./waybar.nix
    ./output.nix
    ./kanshi.nix
    ./menu.nix
  ];
  wayland.windowManager.sway =
    let
      border = 3;
      modifier = "Mod4"; # logo
    in
    {
      enable = true;
      checkConfig = true;
      wrapperFeatures.gtk = true;
      config = {
        # systemd.xdgAutostart = true;
        inherit modifier;
        focus = {
          followMouse = "no";
          wrapping = "no";
          mouseWarping = "container";
          newWindow = "none"; # TODO
        };
        startup = [
          {
            command = "pkill wl-clip-persist; wl-clip-persist --clipboard regular";
            always = true;
          }
        ];
        seat = {
          "*" = {
            hide_cursor = "when-typing enable";
          };
        };
        bindkeysToCode = true;
        up = "k";
        down = "j";
        left = "h";
        right = "l";
        window = {
          titlebar = false;
          inherit border;
        };
        floating = {
          inherit modifier border;
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
        bars = [
          {
            command = "${pkgs.waybar}/bin/waybar";
            mode = "hide";
          }
        ];
        keybindings = { };
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
  # include /etc/sway/config.d/*
}
