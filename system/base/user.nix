{
  cluster,
  user,
  ...
}:
{
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
        "dialout" # serial ports
        "networkmanager"
        "scanner"
        "lp" # printers
        "adbusers" # adb (android)
      ];
      openssh.authorizedKeys = {
        keyFiles = cluster.clientKeyFiles;
      };
    };
  };
  services.getty.autologinUser = user.username;
  hardware.openrazer.users = [ user.username ];
}
