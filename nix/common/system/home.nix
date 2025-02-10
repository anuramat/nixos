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
    useGlobalPkgs = true;
    useUserPackages = true;
    users.${user} = {
      home.username = user;
      home.homeDirectory = config.users.users.${user}.home;
      programs = {
        home-manager.enable = true;

        neovim = {
          enable = true;
          package = unstable.neovim;
          # inputs.neovim-nightly-overlay.packages.${pkgs.system}.default
          extraLuaPackages = ps: [ ps.magick ];
          extraPackages = [ pkgs.imagemagick ];
        };
      };
    };
  };
}
