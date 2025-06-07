{
  config,
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
    ./git.nix
    ./neovim.nix
    ./pass.nix
    ./portal.nix
    ./rice.nix
    ./sway
  ];

  programs = {
    direnv = {
      enable = true;
      silent = true;
    };
  };

  xdg.enable = true; # set XDG vars in .profile
  home = {
    packages = with pkgs; [
      pinentry-tty # just in case
    ];
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
    file = {
      # made for nvi
      ".exrc" = {
        source = ./files/exrc;
      };
    };
  };

  programs = {
    gpg = {
      enable = true;
      homedir = "${config.xdg.dataHome}/gnupg";
    };
    swayimg = {
      # enable = true;
      # settings = {
      # };
    };
    home-manager.enable = true; # TODO huh?

    bash = {
      enable = true;
      # TODO move everything around ffs
      profileExtra = # bash
        ''
          source ${./files/sway_autostart.sh}
        '';
      bashrcExtra = # bash
        ''
          source ${./files/xdg_shims.sh}
          [[ $- == *i* ]] || return
          for f in "${./files/bashrc.d}"/*; do source "$f"; done
          source ${./files/bashrc.sh}

          export _ZO_FZF_OPTS="
          --no-sort
          --exit-0
          --select-1
          --preview='${./files/fzf_preview.sh} {2..}'
          "
          export _ZO_RESOLVE_SYMLINKS="1"
          export _ZO_ECHO=1
          export _ZO_EXCLUDE_DIRS="${config.xdg.cacheHome}/*:/nix/store/*"
        '';
    };

    fzf =
      let
        fd = "fd -u --exclude .git/";
      in
      {
        enable = true;
        defaultCommand = fd;

        changeDirWidgetCommand = "${fd} -t d";
        # changeDirWidgetOptions = "$default_preview";
        # fileWidgetCommand = "$FZF_DEFAULT_COMMAND";
        # fileWidgetOptions = "$default_preview";

        defaultOptions = [
          "--layout=reverse"
          "--keep-right"
          "--info=inline"
          "--tabstop=2"
          "--multi"
          "--height=50%"

          "--tmux=center,90%,80%"

          "--bind='ctrl-/:change-preview-window(down|hidden|)'"
          "--bind='ctrl-j:accept'"
          "--bind='tab:toggle+down'"
          "--bind='btab:toggle+up'"

          "--bind='ctrl-y:preview-up'"
          "--bind='ctrl-e:preview-down'"
          "--bind='ctrl-u:preview-half-page-up'"
          "--bind='ctrl-d:preview-half-page-down'"
          "--bind='ctrl-b:preview-page-up'"
          "--bind='ctrl-f:preview-page-down'"

          "--preview='${./files/fzf_preview.sh} {}'"
        ];
      };

    zoxide = {
      enable = true;
      options = [
        "--cmd j"
      ];
    };

    readline = {
      enable = true;
      extraConfig = builtins.readFile ./files/inputrc;
    };

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
        pager = "less -F";
      };
    };
    zellij = {
      enable = true;
    };
    tmux = {
      enable = true;
      escapeTime = 50;
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
    ripgrep = {
      enable = true;
      arguments = [
        # search over working tree

        # include .*
        "--hidden"
        # symlinks
        "--follow"
        # revert with -s for sensitive
        "--smart-case"

        # with exceptions:

        # VCS
        "--glob=!{.git,.svn}"
        # codegen
        "--glob=!*.pb.go"
      ];
    };
    ripgrep-all = {
      enable = true;
    };
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
    less = {
      enable = true;
      keys = ''
        #env
        LESS = -ir
      '';
    };
    yazi = {
      enable = true;
      settings = {
        plugin.preloaders = [ ];
        plugin.prepend_previewers = [
          {
            name = "/media/**";
            run = "noop";
          }
        ];
        manager.sort_by = "natural";
      };
      keymap = {
        manager.prepend_keymap = [
          {
            on = "y";
            run = [
              ''shell -- for path in "$@"; do echo "file://$path"; done | wl-copy -t text/uri-list''
              "yank"
            ];
          }
          {
            on = "<C-n>";
            run = ''shell -- dragon -x -i -T "$1"'';
          }
        ];
      };
    };
    htop = {
      enable = true;
    };
    btop = {
      enable = true;
    };
  };
}
