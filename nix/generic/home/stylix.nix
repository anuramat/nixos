{ config, pkgs, ... }:
{
  stylix = {
    targets = {
      bemenu.enable = true;
    };
    base16Scheme = {
      stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";
    };
  };
  # lib.stylix.colors = {
  # };
}
