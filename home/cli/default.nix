{ config, lib, ... }:
{
  imports = [
    ./git.nix
    ./packages.nix
  ];
  programs = {
    direnv = {
      enable = true;
      silent = true;
    };
    swayimg = {
      enable = true;
      settings =
        let
          binds = {
            "Shift+Delete" = ''exec rmtrash '%' && echo "File removed: %"; skip_file'';
          };
        in
        {
          "keys.viewer" = binds;
          "keys.galllery" = binds;
        };
    };

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
      # tldr but rust+xdg
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
      keys =
        # less
        ''
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
      # basic
      enable = true;
    };
    btop = {
      # fav
      enable = true;
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
      variables = {
        # completion: logic
        match-hidden-files = true;
        skip-completed-text = true;
        completion-ignore-case = true;
        # '-' == '_':
        completion-map-case = true;

        # completion: visuals
        visible-stats = true;
        colored-stats = true;
        mark-symlinked-directories = true;
        completion-display-width = -1;
        colored-completion-prefix = true;
        completion-prefix-display-length = 5;

        # history
        # reset history modifications after running a command:
        revert-all-at-newline = true;
        history-size = -1;

        # stfu
        completion-query-items = 0;
        page-completions = false;
        show-all-if-ambiguous = true;
        show-all-if-unmodified = true;
      };
    };
  };
}
