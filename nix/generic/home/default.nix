{
  config,
  inputs,
  unstable,
  pkgs,
  ...
}:
let
  user = config.user;
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
        ".exrc" = {
          source = ./exrc;
        };
      };

      programs = {

        home-manager.enable = true; # TODO same here

        bash = {
          enable = true;
          # TODO move everything around ffs
          bashrcExtra = ''
            source ${./xdg_shims.sh}
            [[ $- == *i* ]] || return
            for f in "${./bashrc.d}"/*; do source "$f"; done
            source ${./bashrc.sh}
          '';
        };

        readline = {
          enable = true;
          extraConfig = builtins.readFile ./inputrc;
        };

        librewolf = {
          enable = true;
          settings = {
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

        neovim = {
          enable = true;
          # package = unstable.neovim-unwrapped;
          package = inputs.neovim-nightly-overlay.packages.${pkgs.system}.default;
          extraLuaPackages = ps: [
            # molten:
            ps.magick
          ];
          extraPackages = with pkgs; [
            # molten:
            imagemagick
            python3Packages.jupytext
            # mdmath.nvim
            librsvg
            # mcp
            unstable.github-mcp-server
            mcp-nixos
          ];
          extraPython3Packages =
            ps: with ps; [
              # molten {{{1
              # required:
              pynvim
              jupyter-client
              # images:
              cairosvg # to display svg with transparency
              pillow # open images with :MoltenImagePopup
              pnglatex # latex formulas
              # plotly figures:
              plotly
              kaleido
              # for remote molten:
              requests
              websocket-client
              # misc:
              pyperclip # clipboard support
              nbformat # jupyter import/export
              # }}}
            ];
        };
      };
    };
  };
}
