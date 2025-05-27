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
      Environment = [
        ''PATH="${unstable.foot}/bin:${unstable.yazi}/bin:${pkgs.gnused}/bin:${pkgs.bash}/bin''${PATH:+:$PATH}"''
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
        cmd=${unstable.xdg-desktop-portal-termfilechooser}/share/xdg-desktop-portal-termfilechooser/yazi-wrapper.sh
        default_dir=$HOME/Downloads
        env=TERMCMD=foot
      '';
    };
  };
}
