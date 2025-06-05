{
  cluster,
  config,
  user,
  ...
}:
let
  tz = "Europe/Berlin";
  locale = "en_US.UTF-8";
in
{
  time.timeZone = tz;
  i18n.defaultLocale = locale;
  services.openssh.settings.AllowUsers = [ user.username ];
  users.users = {
    ${user.username} = {
      description = user.fullname;
      isNormalUser = true;
      extraGroups = [
        "nginx"
        "camera" # gphoto2
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
      openssh.authorizedKeys = {
        keys = cluster.miscKeys;
        keyFiles = cluster.clientKeyFiles;
      };
    };
  };
  services.getty.autologinUser = user.username;
  hardware.openrazer.users = [ user.username ];
}
