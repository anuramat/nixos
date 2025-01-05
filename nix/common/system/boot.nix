{ config, ... }:
{
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
        memtest86.enable = true;
        edk2-uefi-shell.enable = true;
        netbootxyz.enable = true;
      };
      efi.canTouchEfiVariables = true;
    };
    # silent boot, suggested by boot.initrd.verbose description:
    consoleLogLevel = 0;
    initrd = {
      verbose = false;
      systemd.enable = true;
    };
    kernelParams = [
      "quiet"
      "udev.log_level=3"
    ];
    plymouth = {
      theme = "breeze"; # package is overridden to use a nixos logo
      enable = true;
    };
  };
  services.getty = {
    greetingLine = ''\l'';
    helpLine = "";
    autologinUser = config.me;
    autologinOnce = true;
  };
}
