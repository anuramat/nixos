{ pkgs, ... }:
{
  imports = [
    ./agents
    ./desktop
    ./gui
    ./packages.nix
    ./vnc.nix
  ];

  stylix.icons =
    let
      dark = "Dracula";
    in
    {
      enable = true;
      inherit dark;
      light = dark; # TODO find a light theme
      package = pkgs.dracula-icon-theme;
      # package = pkgs.xfce.xfce4-icon-theme;
    };

  gui = "wayland";
}
