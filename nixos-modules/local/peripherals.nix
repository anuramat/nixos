{
  inputs,
  pkgs,
  ...
}:
let
  inherit (inputs.self.consts.user) username;
in
{
  users.users.${username}.extraGroups = [ "dialout" ]; # serial ports
  hardware = {
    openrazer.enable = true;
    openrazer.users = [ username ];
    keyboard.zsa.enable = true;
  };
  environment.systemPackages = with pkgs; [
    android-tools
    universal-android-debloater
    jmtpfs
    # easyeffects # takes a while to build
    keymapp # ZSA keyboard thing
    # polychromatic # openrazer frontend
    rpi-imager # raspbery pi
    tamron-lens-control # `tlc`; tty access via dialout
  ];
  services = {
    hardware.openrgb.enable = true;
    udev.packages = [ pkgs.tamron-lens-control ]; # binds cp210x to the lenses
  };
}
