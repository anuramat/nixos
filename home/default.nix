{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./email.nix
    ./mime
    ./lang.nix
    ./term.nix
    ./editor.nix
    ./secret.nix
    ./theme.nix
    ./desktop
    ./cli
  ];

  xdg.enable = true; # set xdg basedir vars in .profile

  home = {
    preferXdgDirectories = true; # this might have made some of the xdg references needless
    activation = {
      removeBrokenConfigLinks =
        lib.hm.dag.entryBefore [ "writeBoundary" ] # bash
          ''
            args=("${config.xdg.configHome}" -maxdepth 1 -xtype l)
            [ -z "''${DRY_RUN:+set}" ] && args+=(-delete) 
            [ -n "''${VERBOSE:+set}" ] && args+=(-print)
            run find "''${args[@]}"
          '';
    };
  };
  # services.podman = {
  #   settings.storage = {
  #     storage.driver = "overlay";
  #     storage.options.overlay.mount_program = "${pkgs.fuse-overlayfs}/bin/fuse-overlayfs";
  #   };
  # };
  xdg.configFile = {
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
  };

  programs = {
    home-manager.enable = true; # TODO huh?

    librewolf = {
      enable = true;
      settings = {
        "browser.urlbar.suggest.history" = false;
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

    matplotlib = {
      enable = true;
      config = { };
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
