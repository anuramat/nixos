{
  config,
  hax,
  lib,
  ...
}:
{
  imports = [
    ./bash
    ./bin
    ./git
    ./keyring.nix
    ./lib.nix
    ./misc.nix
    ./packages.nix
    ./pandoc.nix
    ./readline.nix
    ./search.nix
    ./yazi.nix
  ];

  xdg.enable = true; # set xdg basedir vars in .profile

  programs.home-manager.enable = true; # TODO huh? what does this do

  home.preferXdgDirectories = true;

  xdg.configFile."nixpkgs/config.nix".text = # nix
    ''
      { allowUnfree = true; }
    '';
}
