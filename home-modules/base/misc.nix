{ lib, ... }:
let
  toYAML = lib.generators.toYAML { };
in
{
  xdg.configFile = {
    "qrcp/config.yml".text = toYAML {
      interface = "any";
      keepalive = true;
      port = 9000;
    };
  };

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
      enable = true;
    };

    btop = {
      enable = true;
    };
  };
}
