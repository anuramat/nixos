{ pkgs, lib, ... }:
let
  # TODO refactor or contribute
  chooser = pkgs.xdg-desktop-portal-termfilechooser;
  binPath = pkgs: "PATH=${lib.concatMapStringsSep ":" (v: "${v}/bin") pkgs}";

  dependencies = with pkgs; [
    foot
    yazi
    gnused
    bash
  ];
in
{
  # make sure the dependencies are available
  # systemd.user.services."xdg-desktop-portal-termfilechooser" = {
  #   # overrideStrategy = "asDropin"; # not supported in home manager, TODO contrib?
  #   serviceConfig = {
  #     Environment = [
  #       (binPath dependencies)
  #     ];
  #   };
  # };

  # point it to the file manager
  home.file.".config/xdg-desktop-portal-termfilechooser/config".text = # ini
    ''
      [filechooser]
      cmd=${chooser}/share/xdg-desktop-portal-termfilechooser/yazi-wrapper.sh
      default_dir=$HOME/Downloads
      env=TERMCMD=foot
    '';

  # set as default
  xdg = {
    # not in home manager yet, stolen from nixos
    # TODO somewhere around here declare TERMCMD, reuse in termfilechooser
    # terminal-exec = {
    #   enable = true;
    #   settings = {
    #     default = [ "foot.desktop" ];
    #   };
    # };
    portal = {
      extraPortals = [
        chooser
        pkgs.xdg-desktop-portal-wlr
        pkgs.xdg-desktop-portal-gtk # the rest: <https://wiki.archlinux.org/title/XDG_Desktop_Portal>
      ];
      config =
        let
          portalConfig = {
            "org.freedesktop.impl.portal.FileChooser" = "termfilechooser";
            "org.freedesktop.impl.portal.ScreenCast" = "wlr";
            "org.freedesktop.impl.portal.Screenshot" = "wlr";
            "default" = "gtk";
          };
        in
        {
          common = portalConfig;
        };
    };
  };
}
