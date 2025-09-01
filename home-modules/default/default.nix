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
    ./bash
    ./search.nix
    ./bin
    ./git
    ./misc.nix
    ./packages.nix
    ./readline.nix
    ./yazi.nix
    ./pandoc.nix
  ];

  xdg.enable = true; # set xdg basedir vars in .profile

  programs.home-manager.enable = true; # TODO huh? what does this do

  home.preferXdgDirectories = true;

  xdg.configFile."nixpkgs/config.nix".text = # nix
    ''
      { allowUnfree = true; }
    '';
}
