{
  wayland.windowManager.sway = {
    enable = true;
    config = {
      bars = [ ];
      keybindings = { };
    };
    extraConfig = ''
      include /etc/nixos/config/sway/config.d/00-external_commands
      include /etc/nixos/config/sway/config.d/00-outputs
      include /etc/nixos/config/sway/config.d/01-keys
      include /etc/nixos/config/sway/config.d/02-bar
      include /etc/nixos/config/sway/config.d/xx-autostart
      include /etc/nixos/config/sway/config.d/xx-inputs
      include /etc/nixos/config/sway/config.d/xx-misc
      include /etc/nixos/config/sway/config.d/xx-per_app
    '';
    # config = {
    #   modifier = "Mod4"; # logo
    #   bindkeysToCode = true;
    #   up = "k";
    #   down = "j";
    #   left = "h";
    #   right = "l";
    #   floating = {
    #   };
    # };
    # checkConfig = true;
  };
  # include /etc/sway/config.d/*
}
