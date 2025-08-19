{
  username,
  config,
  ...
}:
let
  fullname = config.home-manager.users.${username}.programs.git.userName;
in
{
  services.openssh.settings.AllowUsers = [ username ];
  users.users = {
    ${username} = {
      description = fullname;
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
        inherit (config.lib.hosts) keyFiles;
      };
    };
  };
  services.getty.autologinUser = username;
  hardware.openrazer.users = [ username ];
}
