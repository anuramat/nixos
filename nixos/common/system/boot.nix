{config, ...}: {
  boot = {
    # silent boot
    consoleLogLevel = 0;
    initrd.verbose = false;
    kernelParams = ["quiet" "udev.log_level=3"];
    # # boot splashscreen
    # # doesn't work with full disk encryption :(
    # plymouth = {
    #   enable = true;
    #   theme = "breeze"; # package is overridden to use a nixos logo
    # };
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelModules = ["v4l2loopback"]; # virtual webcam
    # TODO ?? no fucking idea what this one does, probably doesn't work without it
    extraModulePackages = with config.boot.kernelPackages; [v4l2loopback.out];
    extraModprobeConfig = ''
      # exclusive_caps: compatibility thing
      # https://github.com/umlaeute/v4l2loopback
      options v4l2loopback exclusive_caps=1 card_label="Virtual Camera"
    '';
  };
}