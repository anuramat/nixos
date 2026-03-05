{
  lib,
  inputs,
  config,
  ...
}:
let
  cfg = config.userConfig;
  inherit (cfg) username fullName;
  homeConfig = config.home-manager.users.${username};
in
{
  options = with lib; {
    userConfig = {
      username = mkOption {
        type = types.str;
        description = "primary username for the system";
      };

      # TODO: rename fullName to name?

      fullName = mkOption {
        type = types.str;
        default = homeConfig.programs.git.settings.user.name or (throw "no name provided");
      };

      email = mkOption {
        type = types.str;
        default = homeConfig.programs.git.settings.user.email or (throw "no email provided");
      };
    };
  };
  config = {
    home-manager.users.${username} = {
      imports = [
        inputs.self.homeModules.${username}
      ];
    };

    services.openssh.settings.AllowUsers = [ username ];
    # TODO maybe move closer to specific services that need it
    users.users = {
      ${username} = {
        description = fullName;
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
  };
}
