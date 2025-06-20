{ config, pkgs, ... }:
{
  stylix.iconTheme =
    let
      dark = "Dracula";
    in
    {
      enable = true;
      inherit dark;
      light = dark;
      package = pkgs.dracula-icon-theme;
      # package = pkgs.xfce.xfce4-icon-theme;
    };
  gtk = {
    enable = true;
    gtk2.configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";
  };
  qt.enable = true;
}
