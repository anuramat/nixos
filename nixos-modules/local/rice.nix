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

  # makes nix rebuild the world
  stylix.targets.gtksourceview.enable = false;

  # pretty boot splash screen
  boot.plymouth.enable = true;

  # tty prompt
  services.getty = with lib; {
    greetingLine = mkForce ''\l'';
    helpLine = mkForce "";
  };

  # silent boot, taken from `boot.initrd.verbose` description:
  boot = {
    consoleLogLevel = 0;
    initrd.verbose = false;
    kernelParams = [
      "quiet"
      "udev.log_level=3"
    ];
  };
}
