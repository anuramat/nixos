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
    # Felix file manager configuration
    "felix/config.yaml".text = toYAML { } {
      default = "nvim";
      exec = {
        zathura = [ "pdf" ];
        "feh -." = [
          "jpg"
          "jpeg"
          "png"
          "gif"
          "svg"
          "hdr"
        ];
      };
    };

    # Glow markdown viewer configuration
    "glow/glow.yml".text = toYAML { } {
    };

    # QRCP configuration
    "qrcp/config.yml".text = toYAML { } {
      interface = "any";
      keepalive = true;
      port = 9000;
    };

    # Shellcheck configuration
    "shellcheckrc".text =
      ''
        enable=all
        external-sources=true
      ''
      + lib.strings.concatMapStrings (p: "disable=${p}\n") [
        "SC1003" # incorrect attempt at escaping a single quote?
        "SC1090" # can't follow non constant source
        "SC2015" # A && B || C is not an if-then-else
        "SC2016" # incorrect attempt at expansion?
        "SC2059" # don't use variables in printf format string
        "SC2139" # unintended? expansion in an alias (alias a="$test" instead of '$test')
        "SC2154" # variable referenced but not assigned
        "SC2155" # "local" masks return values
        "SC2250" # quote even if not necessary
        "SC2292" # prefer [[]] over
        "SC2312" # this masks return value
      ];

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
}
