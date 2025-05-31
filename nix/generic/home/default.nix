{
  config,
  inputs,
  pkgs,
  ...
}:
let
  user = config.user.username;
in
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager = {

    backupFileExtension = "backup";
    useGlobalPkgs = true;
    useUserPackages = true;

    users.${user} = {
      xdg.enable = true; # TODO what does this even do

      home.file = {
        # made for nvi
        ".exrc" = {
          source = ./files/exrc;
        };
      };

      programs = {

        home-manager.enable = true; # TODO same here

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
              source ${./bashrc.sh}
            '';
        };

        git = import ./git.nix config;
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

        neovim = import ./neovim.nix;
      };
    };
  };
}
