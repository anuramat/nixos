{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (inputs.self.consts.user) username;
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
    tamron-lens-control # `tlc`; tty access via dialout
  ];
  services = {
    hardware.openrgb.enable = true;
    # bind cp210x to Tamron lenses, which it doesn't claim by default
    udev.extraRules =
      [
        "0002"
        "0005"
      ]
      |> map (pid: ''
        ACTION=="add", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_interface", DRIVER=="", ATTRS{idVendor}=="2cd1", ATTRS{idProduct}=="${pid}", RUN+="${pkgs.runtimeShell} -c '${pkgs.kmod}/bin/modprobe cp210x && echo 2cd1 ${pid} > /sys/bus/usb-serial/drivers/cp210x/new_id'"
      '')
      |> lib.concatStrings;
  };
}
