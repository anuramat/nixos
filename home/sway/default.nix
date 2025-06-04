{ pkgs, ... }:
{
  imports = [
    ./swayidle.nix
    ./swaylock.nix
    ./input.nix
    ./output.nix
  ];
  wayland.windowManager.sway =
    let
      modifier = "Mod4"; # logo
    in
    {
      enable = true;
      config = {
        wrapperFeatures.gtk = true;
        # systemd.xdgAutostart = true;
        inherit modifier;
        focus = {
          followMouse = "no";
          wrapping = "no";
          mouseWarping = true;
          newWindow = "none"; # TODO
        };
        terminal = "foot";
        menu = "bemenu-run";
        modes = {
          resize = { }; # TODO
        };
        startup = [
          # { command = ""; always = true; notification = false; }
        ];
        # for_window [shell="xwayland"] title_format "%title [XWayland]"
        # title_align center
        # mouse_warping container
        # default_orientation auto
        # # TODO relative size
        # floating_maximum_size 1420 x 980
        # floating_minimum_size 600 x 480
        # force_display_urgency_hint 300
        # set $cursor_size 30
        # default_border pixel 3
        # seat * {
        #     hide_cursor when-typing enable
        #     xcursor_theme $cursor_theme $cursor_size
        # }
        # set $cursor_theme Hackneyed
        bindkeysToCode = true;
        up = "k";
        down = "j";
        left = "h";
        right = "l";
        window = {
          titlebar = false;
          border = 3;
        };
        floating = {
          inherit modifier;
          border = { }; # TODO
          titlebar = { }; # TODO
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
        checkConfig = true;
        bars = [
          {
            command = "${pkgs.waybar}/bin/waybar";
            mode = "hide";
            # wayland.windowManager.sway.config.bars.*.command
            # wayland.windowManager.sway.config.bars.*.extraConfig
            # wayland.windowManager.sway.config.bars.*.fonts
            # wayland.windowManager.sway.config.bars.*.hiddenState
            # wayland.windowManager.sway.config.bars.*.id
            # wayland.windowManager.sway.config.bars.*.position
            # wayland.windowManager.sway.config.bars.*.statusCommand
            # wayland.windowManager.sway.config.bars.*.trayOutput
            # wayland.windowManager.sway.config.bars.*.trayPadding
            # wayland.windowManager.sway.config.bars.*.workspaceButtons
            # wayland.windowManager.sway.config.bars.*.workspaceNumbers
          }
        ];
        keybindings = { };
      };
      extraConfig = ''
        include /etc/nixos/config/sway/config.d/00-external_commands
        include /etc/nixos/config/sway/config.d/00-outputs
        include /etc/nixos/config/sway/config.d/01-keys
        include /etc/nixos/config/sway/config.d/xx-autostart
        include /etc/nixos/config/sway/config.d/xx-inputs
        include /etc/nixos/config/sway/config.d/xx-misc
        include /etc/nixos/config/sway/config.d/xx-per_app
      '';
    };
  # include /etc/sway/config.d/*
}
