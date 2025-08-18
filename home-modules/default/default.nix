{
  config,
  hax,
  lib,
  inputs,
  user,
  ...
}@args:
{
  # TODO refactor this mess
  imports =
    with inputs;
    [
      nixvim.homeModules.nixvim
      ./keyring.nix
      inputs.agenix.homeManagerModules.default
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
    )
    ++ (
      if !args ? osConfig then
        [
          {
            nixpkgs.overlays = inputs.self.overlays.default;
          }
          inputs.stylix.homeModules.stylix
          inputs.self.modules.stylix
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
