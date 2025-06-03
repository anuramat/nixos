{ ... }:
{
  services = {
    swayidle = {
      enable = true;
      # idlehint 300 # TODO ask for implementation
      timeouts = [
        {
          timeout = 300;
          command = "swaylock  -f";
        }
        {
          timeout = 600;
          command = "swaymsg   'output * dpms off'";
          resumeCommand = "swaymsg 'output * dpms on'";
        }
        {
          timeout = 999999;
          command = "systemctl suspend";
        }
      ];

      events =
        let
          lock = "swaylock -f";

        in
        [
          {
            event = "before-sleep";
            command = lock;
          }
          {
            event = "unlock";
            command = "pkill -USR1 swaylock";
          }
          {
            event = "lock";
            command = lock;
          }
          {
            event = "lock";
            command = "gpg-connect-agent reloadagent /bye";
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
