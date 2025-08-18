{
  config,
  hax,
  lib,
  ezModules,
  inputs,
  user,
  ...
}@args:
{
  imports = [
    ./keyring.nix
    ./lib.nix
    ./tui
    inputs.agenix.homeManagerModules.default
  ];

  xdg.enable = true; # set xdg basedir vars in .profile

  programs.home-manager.enable = true; # TODO huh? what does this do

  home = {
    preferXdgDirectories = true;
    activation =
      let
        rm = (hax.home lib).removeBrokenLinks;
      in
      {
        removeBrokenLinksConfig = rm config.xdg.configHome;
        removeBrokenLinksHome = rm config.home.homeDirectory;
        removeBrokenLinksBin = rm config.home.sessionVariables.XDG_BIN_HOME;
      };
  };
}
