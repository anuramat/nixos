{
  lib,
  inputs,
  config,
  pkgs,
  ...
}:
let
  toINI = lib.generators.toINI { };
in
{
  imports = [
    ./packages.nix
    ./desktop
    ./viewers.nix
    ./terminals.nix
    ./obs.nix
    ./theme.nix
  ];

  programs = {
    spicetify = {
      enable = true;
      enabledExtensions =
        let
          spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.system};
        in
        with spicePkgs.extensions;
        [
          shuffle
          hidePodcasts
        ];
    };

    librewolf = {
      enable = true;
      settings = {
        "browser.urlbar.suggest.history" = true;
        "widget.use-xdg-desktop-portal.file-picker" = 1;
        "identity.fxaccounts.enabled" = true;

        # since it breaks a lot of pages
        "privacy.resistFingerprinting" = false;

        "sidebar.verticalTabs" = true;
        # required by vertical tabs
        "sidebar.revamp" = true;

        # rejecting all; fallback -- do nothing
        "cookiebanners.service.mode" = 1;
        "cookiebanners.service.mode.privateBrowsing" = 1;
      };
    };
  };
  stylix.targets.librewolf.profileNames = [ "default" ];
  xdg.configFile = {
    # TODO parametrize
    "swappy/config".text = toINI {
      Default = {
        save_dir = "${config.home.homeDirectory}/img/screen";
        save_filename_format = "swappy-%Y-%m-%d_%Hh%Mm%Ss.png";
        show_panel = true;
        line_size = 5;
        text_size = 20;
        text_font = "${config.stylix.fonts.serif.name}";
        paint_mode = "brush";
        early_exit = false;
        fill_shape = false;
      };
    };

    "openrazer/persistence.conf".text = toINI {
      PM2143H14804655 = {
        dpi_x = 1800;
        dpi_y = 1800;
        poll_rate = 500;
        logo_active = true;
        logo_brightness = 75;
        logo_effect = "spectrum";
        logo_colors = "0 255 0 0 255 255 0 0 255";
        logo_speed = 1;
        logo_wave_dir = 1;
      };
    };
  };
}
