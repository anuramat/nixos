{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) getExe;
in
{
  services = {
    swayidle =
      let
        screen =
          let
            swaymsg = "${pkgs.sway}/bin/swaymsg";
          in
          {
            off = "${swaymsg} 'output * power off'";
            on = "${swaymsg} 'output * power on'";
          };
        lock =
          let
            screen = "${lib.getExe pkgs.swaylock} -f";
            keyring = getExe config.lib.keyring.lock;
          in
          "${keyring}; ${screen}";
      in
      {
        enable = true;
        # idlehint = 300; # TODO implement/beg
        # BUG duplicate events overwrite previous definitions: <https://github.com/nix-community/home-manager/issues/4432>
        timeouts = [
          {
            timeout = 300;
            command = lock;
          }
          {
            timeout = 600;
            command = screen.off;
            resumeCommand = screen.on;
          }
        ];
        events = [
          {
            event = "before-sleep";
            command = lock;
          }
          {
            event = "lock";
            command = lock;
          }
        ];
      };
  };
}
