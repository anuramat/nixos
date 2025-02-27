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
      home.username = user;
      home.homeDirectory = config.users.users.${user}.home;

      xdg.enable = true;

      # #!/usr/bin/env bash
      # # shellcheck source-path=home
      # . "$HOME/.bashrc"
      programs.bash = {
        enable = true;
        bashrcExtra = ''
          source ${./bashrc.sh}
        '';
      };

      programs = {
        home-manager.enable = true;

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
