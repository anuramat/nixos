# this all could be replaced with a proper environment for the corresponding systemd service
{
  config,
  inputs,
  unstable,
  pkgs,
  ...
}:
let
  user = config.user;
in
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  # make sure the dependencies are available
  systemd.user.services."xdg-desktop-portal-termfilechooser" = {
    overrideStrategy = "asDropin";
    serviceConfig = {
      Environment = with pkgs; [
        ''PATH="${foot}/bin:${yazi}/bin:${gnused}/bin:${bash}/bin''${PATH:+:$PATH}"''
      ];
    };
  };

  home-manager = {
    users.${user} = {
      # TODO: move default term to a variable or something?
      # or figure out how to make systemd services read env vars
      # maybe use xdg term thing?
      home.file.".config/xdg-desktop-portal-termfilechooser/config".text = ''
        [filechooser]
        cmd=${pkgs.xdg-desktop-portal-termfilechooser}/share/xdg-desktop-portal-termfilechooser/yazi-wrapper.sh
        default_dir=$HOME/Downloads
        env=TERMCMD=foot
      '';
    };
  };

  xdg = {
    portal = {
      extraPortals = [
        pkgs.xdg-desktop-portal-termfilechooser # file picker; not in stable yet TODO
      ];
      config =
        let
          portalConfig = {
            "org.freedesktop.impl.portal.FileChooser" = "termfilechooser";
          };
        in
        {
          sway = portalConfig;
        };
    };
  };
}
