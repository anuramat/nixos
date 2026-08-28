{
  inputs,
  pkgs,
  ...
}:
let
  inherit (inputs.self.user) username;
in
{
  users.users.${username}.extraGroups = [ "dialout" ]; # serial ports
  # NOTE 2026-05-29 razer commented out because it breaks with newer kernel
  hardware = {
    # openrazer.enable = true;
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
  ];
  services = {
    hardware.openrgb.enable = true;
  };
}
