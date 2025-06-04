{ pkgs, ... }:
{
  services = {
    swayidle =
      let
        inherit (pkgs)
          swaylock
          sway
          killall
          systemd
          ;
        lock = "${swaylock}/bin/swaylock -f";
        lockKeys = "${killall}/bin/killall -s SIGHUP gpg-agent";
        unlock = "${killall}/bin/killall -s USR1 swaylock";
        sleep = "${systemd}/bin/systemctl suspend";
        screenOff = "${sway}/bin/swaymsg 'output * dpms off'";
        screenOn = "${sway}/bin/swaymsg 'output * dpms on'";
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
}
