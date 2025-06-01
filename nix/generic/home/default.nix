{
  config,
  pkgs,
  ...
}@args:
{

  imports = [
    ./git.nix
    ./neovim.nix
  ];

  xdg.enable = true; # set XDG vars in .profile

  home = {
    packages = [ ];
    file = {
      # made for nvi
      ".exrc" = {
        source = ./files/exrc;
      };
    };
  };

  services.pass-secret-service.enable = true; # secret service api -- exposes password-store over dbus
  services.gpg-agent = {
    enable = true;
    enableBashIntegration = true;
    pinentry = {
      package = pkgs.pinentry-all;
      program = "pinentry-bemenu";
    }
  };
  programs = {
    gpg = {
      enable = true;
      homedir = "${config.xdg.dataHome}/gnupg";
    };
    bemenu = {
      enable = true;
      settings = {
        line-height = 28;
        prompt = "open";
        list = 5;
        fn = "Hack Nerd Font 16";
        ignorecase = true;
      };
    };
    home-manager.enable = true; # TODO huh?
    password-store = {
      enable = true;
    };

    gh = {
      enable = true;
      settings = {
        extensions = with pkgs; [
          gh-f
          gh-copilot
          # # wait until they appear
          # copilot-insights
          # token
        ];
        git_protocol = "ssh";
        prompt = true;
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

    fzf =
      let
        fd = "fd -u --exclude .git/";
      in
      {
        enable = true;
        enableBashIntegration = true;
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
      enableBashIntegration = true;
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
  };
}
