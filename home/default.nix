{
  config,
  hax,
  lib,
  inputs,
  ...
}:
{
  imports = with inputs; [
    nixvim.homeModules.nixvim
    spicetify-nix.homeManagerModules.spicetify
    ./lang
    ./misc.nix
    ./email.nix
    ./mime
    ./llm
    ./editor.nix
    ./keyring.nix
    ./theme.nix
    ./gui
    ./tui
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
