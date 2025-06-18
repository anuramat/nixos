{
  config,
  helpers,
  pkgs,
  lib,
  user,
  inputs,
  ...
}:
{
  imports = [
    inputs.nixvim.homeModules.nixvim
    ./lang
    ./misc.nix
    ./email.nix
    ./mime
    ./llm
    ./term.nix
    ./editor.nix
    ./secret.nix
    ./theme.nix
    ./desktop
    ./cli
  ];

  xdg.enable = true; # set xdg basedir vars in .profile

  programs.home-manager.enable = true; # TODO huh? what does this do

  home = {
    preferXdgDirectories = true;
    activation = {
      removeBrokenLinksConfig = helpers.common.removeBrokenLinks config.xdg.configHome;
      removeBrokenLinksHome = helpers.common.removeBrokenLinks config.home.homeDirectory;
      removeBrokenLinksBin = helpers.common.removeBrokenLinks config.home.sessionVariables.XDG_BIN_HOME;
    };
  };
}
