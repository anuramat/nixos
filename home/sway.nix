{
  services = {
    swayidle =
      let
        lock = "swaylock -f";
        lockKeys = "killall -s SIGHUP gpg-agent";
        unlock = "killall -s USR1 swaylock";
        sleep = "systemctl suspend";
        screenOff = "swaymsg 'output * dpms off'";
        screenOn = "swaymsg 'output * dpms on'";
      in
      {
        enable = true;
        # idlehint = 300; # TODO ask for implementation
        # TODO maybe also turn command into commands in events and timeouts
        timeouts = [
          {
            timeout = 300;
            command = lock;
          }
          {
            timeout = 600;
            command = screenOff;
            resumeCommand = screenOn;
          }
          {
            timeout = 999999;
            command = sleep;
          }
        ];
        events = [
          {
            event = "before-sleep";
            command = lock;
          }
          {
            event = "unlock";
            command = unlock;
          }
          {
            event = "lock";
            command = lock;
          }
          {
            event = "lock";
            command = lockKeys;
          }
        ];
      };
  };
  # wayland.windowManager.sway = {
  #   config = {
  #     modifier = "Mod4"; # logo
  #     bindkeysToCode = true;
  #     up = "k";
  #     down = "j";
  #     left = "h";
  #     right = "l";
  #     floating = {
  #     };
  #   };
  #   checkConfig = true;
  # };
}
