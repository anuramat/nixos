{
  config,
  pkgs,
  ...
}:
{

  xdg.enable = true; # set XDG vars in .profile

  home.file = {
    # made for nvi
    ".exrc" = {
      source = ./files/exrc;
    };
  };

  services.pass-secret-service.enable = true; # secret service api -- exposes password-store over dbus
  programs = {
    home-manager.enable = true; # TODO huh?
    password-store = {
      enable = true;
      settings = {
        PASSWORD_STORE_DIR = "${config.xdg.dataHome}/pass";
      };
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
      bashrcExtra = # bash
        ''
          source ${./files/xdg_shims.sh}
          [[ $- == *i* ]] || return
          for f in "${./files/bashrc.d}"/*; do source "$f"; done
          source ${./files/bashrc.sh}
        '';
    };

    git = (import ./git.nix) config;
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

    neovim = import ./neovim.nix pkgs;
  };
}
