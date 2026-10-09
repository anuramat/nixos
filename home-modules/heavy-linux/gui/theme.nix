{ config, ... }:
{
  gtk = {
    enable = true;
    gtk4.theme = config.gtk.theme;
  };
  qt.enable = true;
}
