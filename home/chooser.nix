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
  systemd.user.services."xdg-desktop-portal-termfilechooser" = {
    overrideStrategy = "asDropin";
    serviceConfig = {
      Environment = [
        (binPath dependencies)
      ];
    };
  };

  # point it to the file manager
  home.file.".config/xdg-desktop-portal-termfilechooser/config".text = # ini
      ''
        [filechooser]
        cmd=${chooser}/share/xdg-desktop-portal-termfilechooser/yazi-wrapper.sh
        default_dir=$HOME/Downloads
        env=TERMCMD=foot
      '';
  };

  # set as default
  xdg = {
    portal = {
      extraPortals = [
        chooser
      ];
      config =
        let
          portalConfig = {
            "org.freedesktop.impl.portal.FileChooser" = "termfilechooser";
          };
        in
        {
          common = portalConfig;
        };
    };
  };
}
