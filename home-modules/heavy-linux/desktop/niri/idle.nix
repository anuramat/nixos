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
        {
          event = "unlock";
          command = unlock;
          # TODO also turn on screen
        }
      ];
    };
  };
}
