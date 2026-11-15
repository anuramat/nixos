{
  pkgs,
  lib,
  config,
  ...
}:
let
  chooser = pkgs.xdg-desktop-portal-termfilechooser;
  # The portals are D-Bus activated by whichever client asks first, also between niri sessions
  # (right after niri quits, before the next one exports WAYLAND_DISPLAY), and then run without
  # a display: the file chooser's terminal can't open. Requisite= fails an activation outside
  # the session; After= makes one during niri's start wait until niri has exported its
  # environment.
  inSession = ''
    [Unit]
    After=${config.wayland.systemd.target}
    Requisite=${config.wayland.systemd.target}
  '';
in
{
  xdg.configFile = {
    "systemd/user/xdg-desktop-portal.service.d/session.conf".text = inSession;
    "systemd/user/xdg-desktop-portal-termfilechooser.service.d/session.conf".text = inSession;
    "systemd/user/xdg-desktop-portal-gtk.service.d/session.conf".text = inSession;
    "systemd/user/xdg-desktop-portal-wlr.service.d/session.conf".text = inSession;
    "xdg-desktop-portal-termfilechooser/config".text =
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
        # no single instance: the wrapper blocks until the terminal exits
        term = "${config.home.sessionVariables.TERMCMD} --gtk-single-instance=false -e";
      in
      # ini
      ''
        [filechooser]
        cmd=${lib.getExe wrapper}
        default_dir=$HOME/Downloads
        env=TERMCMD=${term}
      '';
  };

  xdg = {
    portal = {
      enable = true;
      extraPortals = [
        chooser
        pkgs.xdg-desktop-portal-wlr
        pkgs.xdg-desktop-portal-gtk
        # TODO read and verify that all needs are covered with no overlap <https://wiki.archlinux.org/title/XDG_Desktop_Portal>
      ];
      config.common = {
        "org.freedesktop.impl.portal.FileChooser" = "termfilechooser";
        "org.freedesktop.impl.portal.ScreenCast" = "wlr";
        "org.freedesktop.impl.portal.Screenshot" = "wlr";
        default = "gtk";
      };
    };
  };
}
