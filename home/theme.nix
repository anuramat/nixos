{ pkgs, ... }:
{
  stylix = {
    targets = {
      bemenu.enable = true;
      librewolf.profileNames = [ "default" ];
      neovim.enable = false;
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
