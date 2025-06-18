{ pkgs, lib, ... }:
let
  toYAML = lib.generators.toYAML { };
in
# TODO reformat file
{
  xdg.configFile = {
    # TODO why not use this instead?
    # services.podman = {
    #   settings.storage = {
    #     storage.driver = "overlay";
    #     storage.options.overlay.mount_program = "${pkgs.fuse-overlayfs}/bin/fuse-overlayfs";
    #   };
    # };
    podman = {
      text = # conf
        ''
          # magic stolen from <https://github.com/containers/podman/issues/11220> to speed up --userns=keep-id
          [storage]
          driver = "overlay"
          [storage.options.overlay]
          mount_program = "${pkgs.fuse-overlayfs}/bin/fuse-overlayfs"
        '';
      target = "containers/storage.conf";
    };
    # Felix file manager configuration
    "felix/config.yaml".text = toYAML {
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
    "glow/glow.yml".text = toYAML {
    };
    # QRCP configuration
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
      # basic
      enable = true;
    };

    btop = {
      # fav
      enable = true;
    };
  };
}
