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
      export PATH="${unstable.foot}/bin:${unstable.yazi}/bin''${PATH:+:$PATH}"
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
      # TODO: move default term to a variable or something?
      # or figure out how to make systemd services read env vars
      # maybe use xdg term thing?
      home.file.".config/xdg-desktop-portal-termfilechooser/config".text = ''
        [filechooser]
        cmd=${wrapper}
        default_dir=$HOME/Downloads
        env=TERMCMD=foot
      '';
    };
  };
}
