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
  wrapper = pkgs.writeTextFile {
    name = "nix_wrapper.sh";
    text = ''
      #!/bin/sh
      export PATH="${pkgs.foot}/bin:${pkgs.yazi}/bin''${PATH:+:$PATH}"
      ${unstable.xdg-desktop-portal-termfilechooser}/share/xdg-desktop-portal-termfilechooser/yazi-wrapper.sh "$@"
    '';
    executable = true;
  };
in
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager = {
    users.${user} = {
      home.file.".config/xdg-desktop-portal-termfilechooser/config".text = ''
        [filechooser]
        cmd=${wrapper}
        default_dir=$HOME/Downloads
        env=TERMCMD=foot
      '';
    };
  };
}
