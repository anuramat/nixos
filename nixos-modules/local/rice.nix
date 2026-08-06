{
  lib,
  inputs,
  ...
}:
{
  imports = [
    inputs.stylix.nixosModules.stylix
    inputs.self.sharedModules.stylix
  ];
  stylix.autoEnable = true;
  # the NixOS target is an overlay: every theme change rebuilds all
  # gtksourceview rdeps from source (inkscape et al); the HM target
  # themes via xdg.dataFile instead, no rebuilds
  stylix.targets.gtksourceview.enable = false;
  # loading screen rice
  boot.plymouth.enable = true;
  # tty rice; impossible to start a wm in it
  # may be worth using if I figure out how to have it only on one tty
  services.kmscon.enable = false;
  # minimal tty prompt
  services.getty = with lib; {
    greetingLine = mkForce ''\l'';
    helpLine = mkForce "";
  };
  # silent boot, taken from boot.initrd.verbose description:
  boot = {
    consoleLogLevel = 0;
    initrd = {
      verbose = false; # silent boot
    };
    kernelParams = [
      "quiet"
      "udev.log_level=3"
    ];
  };
}
