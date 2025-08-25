{ pkgs, lib, ... }:
let
  chooser = pkgs.xdg-desktop-portal-termfilechooser;
in
{
  xdg.configFile."xdg-desktop-portal-termfilechooser/config".text =
    let
      wrapper = pkgs.writeShellApplication {
        name = "yazi-wrapper";
        runtimeInputs = with pkgs; [
          yazi
          gnused
          bash
        ];
        text = builtins.readFile "${chooser}/share/xdg-desktop-portal-termfilechooser/yazi-wrapper.sh";
      };
    in
    # ini
    ''
      [filechooser]
      cmd=${lib.getExe wrapper}
      default_dir=$HOME/Downloads
      env=TERMCMD=${pkgs.foot}/bin/foot
    '';

  xdg = {
    portal = {
      enable = true;
      extraPortals = [
        chooser
        pkgs.xdg-desktop-portal-wlr
        pkgs.xdg-desktop-portal-gtk
        # TODO read and verify that all needs are covered with no overlap <https://wiki.archlinux.org/title/XDG_Desktop_Portal>
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
