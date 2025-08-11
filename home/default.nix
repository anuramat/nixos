{
  config,
  hax,
  lib,
  inputs,
  ...
}@args:
{
  imports =
    with inputs;
    [
      nixvim.homeModules.nixvim
      ./keyring.nix
      ./lib.nix
      ./tui
    ]
    ++ (
      if !(args ? cluster) || !args.cluster.this.server then
        [
          ./editor.nix
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
