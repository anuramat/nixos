{
  config,
  cluster,
  hax,
  lib,
  inputs,
  ...
}:
{
  imports =
    with inputs;
    [
      nixvim.homeModules.nixvim
      ./editor.nix
      ./keyring.nix
      ./lib.nix
      ./tui
    ]
    ++ (
      if !cluster.this.server then
        [
          ./mime
          ./gui
          ./email.nix
          ./agents
          spicetify-nix.homeManagerModules.spicetify
          ./lang
        ]
      else
        [ ]
    );

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
