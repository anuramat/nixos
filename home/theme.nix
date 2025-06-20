{ pkgs, ... }:
{
  stylix = {
    targets = {
      neovim.plugin = "base16-nvim";
      librewolf.profileNames = [ "default" ]; # TODO reference variable
    };
  };
  gtk.enable = true;
  qt.enable = true;
  home.pointerCursor = {
    enable = true;
    size = 20;
    name = "Hackneyed";
    package = pkgs.hackneyed;
  };
}
