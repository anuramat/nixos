{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) getExe;

  screen =
    let
      niri = getExe pkgs.niri;
    in
    {
      off = "${niri} msg action power-off-monitors";
      on = "${niri} msg action power-on-monitors";
    };

  inherit (config.lib.lockscreen) lock unlock;

in
{
  services = {
    swayidle = {
      enable = true;
      # idlehint = 300; # TODO implement/beg
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
      events = {
        before-sleep = lock;
        lock = lock;
        unlock = unlock; # TODO also turn on screen
      };
    };
  };
}
