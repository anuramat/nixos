{
  pkgs,
  unstable,
  ...
}:
{
  hardware = {
    flipperzero.enable = true;
    openrazer.enable = true;
  };
  environment.systemPackages = [
    unstable.keymapp # ZSA keyboard thing
    pkgs.polychromatic # openrazer frontend
    pkgs.rpi-imager # raspbery pi
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
