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
    activation =
      let
        rm = (helpers.home lib).removeBrokenLinks;
      in
      {
        removeBrokenLinksConfig = rm config.xdg.configHome;
        removeBrokenLinksHome = rm config.home.homeDirectory;
        removeBrokenLinksBin = rm config.home.sessionVariables.XDG_BIN_HOME;
      };
  };
}
