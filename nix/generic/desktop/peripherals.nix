{
  pkgs,
  ...
}:
{
  programs.adb.enable = true; # android stuff
  hardware = {
    flipperzero.enable = true;
    openrazer.enable = true;
  };
  environment.systemPackages = with pkgs; [
    keymapp # ZSA keyboard thing
    polychromatic # openrazer frontend
    rpi-imager # raspbery pi
  ];
  services = {
    # ZSA Voyager
    udev.extraRules = ''
      # Rules for Oryx web flashing and live training
      KERNEL=="hidraw*", ATTRS{idVendor}=="16c0", MODE="0664", GROUP="plugdev"
      KERNEL=="hidraw*", ATTRS{idVendor}=="3297", MODE="0664", GROUP="plugdev"
      # Keymapp Flashing rules for the Voyager
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="3297", MODE:="0666", SYMLINK+="ignition_dfu"
    '';
    hardware.openrgb.enable = true;
  };
}
