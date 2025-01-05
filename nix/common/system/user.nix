{
  cluster,
  ...
}:
let
  username = "anuramat";
  fullname = "Arsen Nuramatov";
  tz = "Europe/Berlin";
  locale = "en_US.UTF-8";
in
{
  time.timeZone = tz;
  i18n.defaultLocale = locale;
  services.openssh.settings.AllowUsers = [ username ];
  users.users.${username} = {
    description = fullname;
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
    openssh.authorizedKeys = {
      keys = cluster.miscKeys;
      keyFiles = cluster.clientKeyFiles;
    };
  };
  services.getty.autologinUser = username;
  hardware.openrazer.users = [ username ];
}
