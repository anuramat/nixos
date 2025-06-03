{ lib, pkgs, ... }:
let
  useRed = false;
in
{
  programs = {
    swaylock = {
      # needs pam; it's already configured by programs.sway on nixos
      enable = true;
      settings =
        {
          ignore-empty-password = true;
          indicator-caps-lock = true;

          # red
        }
        // (
          if useRed then
            {
              color = "ff0000";

              inside-color = "ff0000";
              line-color = "000000";
              ring-color = "ff0000";

              inside-clear-color = "ff0000";
              line-clear-color = "ff0000";
              ring-clear-color = "ff0000";

              inside-wrong-color = "ff0000";
              line-wrong-color = "000000";
              ring-wrong-color = "ff0000";

              inside-ver-color = "ff0000";
              line-ver-color = "ff0000";
              ring-ver-color = "ff0000";

              layout-bg-color = "00000000";
              layout-border-color = "00000000";
              layout-text-color = "000000";

              key-hl-color = "000000";

              # remove the text
              text-caps-lock-color = "00000000";
              text-clear-color = "00000000";
              text-color = "00000000";
              text-ver-color = "00000000";
              text-wrong-color = "00000000";
            }
          else
            { }
        );
    };
  };
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
  wayland.windowManager.sway = {
    enable = true;
    # config = {
    #   modifier = "Mod4"; # logo
    #   bindkeysToCode = true;
    #   up = "k";
    #   down = "j";
    #   left = "h";
    #   right = "l";
    #   floating = {
    #   };
    # };
    # checkConfig = true;
  };
}
