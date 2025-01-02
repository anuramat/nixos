{ user, hostname, ... }:
{
  networking.hostName = hostname;
  documentation.man.generateCaches = true; # apropos
  hardware.enableAllFirmware = true; # regardless of license
  time.timeZone = user.timezone;
  i18n.defaultLocale = user.defaultLocale;
  environment.extraOutputsToInstall = [ "info" ];
  users.users.${user.username} = {
    description = user.fullname;
    isNormalUser = true;
    extraGroups = [
      "wheel" # root
      "video" # screen brightness
      "network" # wifi
      "docker" # docker
      "audio" # just in case (?)
      "syncthing" # just in case default syncthing settings are used
      "plugdev" # pluggable devices : required by zsa voyager
      "vboxusers" # virtualbox
      # "input" # le unsecure (?), supposed to be used to get lid state, apparently not required
      "dialout" # serial ports
      "networkmanager"
      "scanner"
      "lp" # printers
      "adbusers" # adb (android)
    ];
  };
}
