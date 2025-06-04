{ pkgs, lib, ... }:
let
  chooser = pkgs.xdg-desktop-portal-termfilechooser;

  # TODO contribute
  dependencies = with pkgs; [
    yazi
    gnused
    bash
  ];
  wrapper = pkgs.writeTextFile {
    name = "nix_wrapper.sh";
    text = ''
      #!/bin/sh
      export PATH=${lib.makeBinPath dependencies}
      ${chooser}/share/xdg-desktop-portal-termfilechooser/yazi-wrapper.sh "$@"
    '';
    executable = true;
  };

in
{
  # point it to the file manager
  home.file.".config/xdg-desktop-portal-termfilechooser/config".text = # ini
    ''
      [filechooser]
      cmd=${wrapper}
      default_dir=$HOME/Downloads
      env=TERMCMD=foot
    '';

  # set as default
  xdg = {
    portal = {
      enable = true;
      extraPortals = [
        # this fucking shit is supposed to create a systemd service
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
