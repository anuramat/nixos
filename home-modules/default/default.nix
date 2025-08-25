{
  config,
  hax,
  lib,
  ...
}:
{
  imports = [
    ./keyring.nix
    ./lib.nix
    ./tui
  ];

  xdg.enable = true; # set xdg basedir vars in .profile

  programs.home-manager.enable = true; # TODO huh? what does this do

  home.preferXdgDirectories = true;
}
