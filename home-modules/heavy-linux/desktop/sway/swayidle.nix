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

  erotic = pkgs.writeShellApplication {
    name = "erotic";
    runtimeInputs = [
      pkgs.procps
      pkgs.swaylock
    ];
    # TODO auto disown
    text = ''
      SWAYSOCK=$(systemctl --user show-environment | sed -n 's/^SWAYSOCK=//p')
      export SWAYSOCK
      WAYLAND_DISPLAY=wayland-1
      export WAYLAND_DISPLAY

      # unlock
      pkill -SIGUSR1 swaylock || true
      # stop idle service
      systemctl --user --machine="$USER@.host" stop swayidle.service
      # enable screen
      SWAYSOCK=$(systemctl --user show-environment | sed -n 's/^SWAYSOCK=//p') ${screen.on}
      # set brightness
      swaymsg 'exec "${lib.getExe pkgs.brightnessctl} s 100%"'
      ddcutil setvcp 10 100 --display 1
      # lock with the chosen color
      swaylock --color "$1"
      # restart idle
      systemctl --user --machine="$USER@.host" start swayidle.service
    '';
  };

  unerotic = pkgs.writeShellApplication {
    name = "unerotic";
    runtimeInputs = [
      pkgs.procps
      pkgs.swaylock
    ];
    text = ''
      SWAYSOCK=$(systemctl --user show-environment | sed -n 's/^SWAYSOCK=//p')
      export SWAYSOCK
      WAYLAND_DISPLAY=wayland-1
      export WAYLAND_DISPLAY

      pkill -SIGUSR1 swaylock || true
      swaylock --daemonize
      ${screen.off}
    '';
  };
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
      ];
    };
  };
  home.packages = [
    erotic
    unerotic
  ];
}
