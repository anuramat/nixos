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
            "privacy.resistFingerprinting" = false;
            "sidebar.revamp" = true;
            "sidebar.verticalTabs" = true;
          };

        };

        neovim = {
          enable = true;
          package = unstable.neovim-unwrapped;
          # inputs.neovim-nightly-overlay.packages.${pkgs.system}.default
          extraLuaPackages = ps: [ ps.magick ];
          extraPackages = [ pkgs.imagemagick ];
          extraPython3Packages =
            ps: with ps; [
              # these are from molten I think
              pynvim
              jupyter-client
              cairosvg # for image rendering
              pnglatex # for image rendering
              plotly # for image rendering
              pyperclip
              ipython
              nbformat
            ];
        };

      };
    };
  };
}
