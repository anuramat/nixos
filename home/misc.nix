{
  config,
  lib,
  ...
}:
let
  toYAML = lib.generators.toYAML { };
  toINI = lib.generators.toINI { };
in
{
  xdg.configFile = {
    # Swappy screenshot annotation configuration
    "swappy/config".text = toINI { } {
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

    # OpenRazer configuration
    "openrazer/persistence.conf".text = toINI { } {
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
  programs = {
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

    zathura = {
      enable = true;
      options = {
        adjust-open = "width";
        window-title-home-tilde = true;
        statusbar-basename = true;
        selection-clipboard = "clipboard";
        synctex = true;
        synctex-editor-command = "texlab inverse-search -i %{input} -l %{line}"; # result should be quoted I think
      };
    };

    mpv = {
      config = {
        profile = "gpu-hq";
        gpu-context = "wayland";
        hwdec = "auto-safe";
        vo = "gpu";
        force-window = true;
        ytdl-format = "bestvideo+bestaudio";
        cache-default = 4000000;
      };
    };
  };
}
