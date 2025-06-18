{
  config,
  hax,
  pkgs,
  lib,
  user,
  inputs,
  ...
}:
{
  imports = [
    inputs.nixvim.homeModules.nixvim
    inputs.agenix.homeManagerModules.default
    ./lang
    ./misc.nix
    ./email.nix
    ./mime
    ./llm
    ./term.nix
    ./editor.nix
    ./keyring.nix
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
        rm = (hax.home lib).removeBrokenLinks;
      in
      {
        removeBrokenLinksConfig = rm config.xdg.configHome;
        removeBrokenLinksHome = rm config.home.homeDirectory;
        removeBrokenLinksBin = rm config.home.sessionVariables.XDG_BIN_HOME;
      };
  };
}
