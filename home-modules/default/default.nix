{
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
    ./readline.nix
    ./search.nix
    ./typst.nix
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
