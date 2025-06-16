{
  programs = {
    tealdeer = {
      enable = true;
      settings = {
        display = {
          compact = false;
          use_pager = true;
        };
        updates = {
          auto_update = true;
        };
      };
    };

    info.enable = true;

    direnv = {
      enable = true;
      silent = true;
    };

    less = {
      enable = true;
      keys =
        # less
        ''
          #env
          LESS = -ir
        '';
    };

    zoxide = {
      enable = true;
      options = [
        "--cmd j"
      ];
    };

    fd = {
      enable = true;
      ignores = [
        ".git/"
        "*.pb.go"
      ];
    };

    bat = {
      enable = true;
      config = {
        italic-text = "always";
        pager = "less";
      };
    };

    zellij = {
      enable = true;
    };

    tmux = {
      enable = true;
      escapeTime = 50;
      extraConfig = # tmux
        ''
          set -g allow-passthrough on
        '';
    };

    htop = {
      # basic
      enable = true;
    };

    btop = {
      # fav
      enable = true;
    };
  };
}
